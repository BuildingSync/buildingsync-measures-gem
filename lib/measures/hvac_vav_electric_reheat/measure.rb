class HvacVavElectricReheat < OpenStudio::Measure::ModelMeasure
  def name = 'VAV with Electric Reheat HVAC'
  def description = 'Creates built-up VAV with electric reheat or replaces HVAC dedicated to selected zones.'
  def modeler_description = 'Uses one VAV PFP Boxes synthesis path; replacement rejects partial shared-loop removal and removes pre-existing plant loops left without loads.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    operations = OpenStudio::StringVector.new
    %w[create replace].each { |value| operations << value }
    operation = OpenStudio::Measure::OSArgument.makeChoiceArgument('operation', operations, true)
    operation.setDisplayName('Operation')
    operation.setDefaultValue('create')
    args << operation
    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', false)
    names.setDisplayName('Target Zone Names')
    names.setDescription('Comma-separated exact thermal-zone names, or a JSON array of exact names (for names containing commas). Blank selects all zones for create; replace requires explicit names.')
    names.setDefaultValue('')
    args << names
    choices = OpenStudio::StringVector.new
    ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010', '90.1-2013', '90.1-2016', '90.1-2019']
      .each { |value| choices << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', choices, true)
    template.setDisplayName('Standards Template')
    template.setDefaultValue('90.1-2019')
    args << template
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    operation = runner.getStringArgumentValue('operation', user_arguments)
    require 'json'
    text = runner.getStringArgumentValue('target_zone_names', user_arguments).strip
    begin
      requested = text.start_with?('[') ? JSON.parse(text) : text.split(',').map(&:strip)
    rescue JSON::ParserError
      requested = nil
    end
    unless requested.is_a?(Array) && requested.all? { |zone_name| zone_name.is_a?(String) }
      runner.registerError('target_zone_names must be comma-separated names or a JSON array of strings.')
      return false
    end
    requested = requested.reject { |zone_name| zone_name.strip.empty? }.uniq
    if operation == 'replace' && requested.empty?
      runner.registerError('Replace requires at least one exact target_zone_names value.')
      return false
    end
    zones = requested.empty? ? model.getThermalZones.to_a : model.getThermalZones.select { |zone| requested.include?(zone.name.to_s) }
    missing = requested - zones.map { |zone| zone.name.to_s }
    unless missing.empty?
      runner.registerError("Thermal zones not found: #{missing.join(', ')}")
      return false
    end
    if zones.empty?
      runner.registerError('No target thermal zones were found.')
      return false
    end
    affected = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }
    if operation == 'create'
      conflicts = zones.select { |zone| !zone.equipment.empty? || affected.any? { |air_loop| air_loop.thermalZones.include?(zone) } }
      unless conflicts.empty?
        runner.registerError("VAV PFP Boxes creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
    else
      shared = affected.select { |air_loop| (air_loop.thermalZones.to_a - zones).any? }
      unless shared.empty?
        details = shared.map { |air_loop| "#{air_loop.name}: also serves #{(air_loop.thermalZones.to_a - zones).map { |zone| zone.name.to_s }.join(', ')}" }
        runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
        return false
      end
    end

    begin
      require 'openstudio-standards'
      plant_handles = model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }
      loaded_plants = loaded_plant_loop_handles(model)
      removed = 0
      if operation == 'replace'
        vrf_units = model.getAirConditionerVariableRefrigerantFlows.reject { |vrf| vrf.terminals.empty? }
        removed = zones.sum do |zone|
          equipment = zone.equipment.to_a
          equipment.each(&:remove)
          equipment.size
        end
        affected.each(&:remove)
        # Outdoor units whose last terminal was removed would otherwise remain disconnected.
        vrf_units.select { |vrf| vrf.terminals.empty? }.each(&:remove)
      end
      before = model.getAirLoopHVACs.map { |air_loop| air_loop.handle.to_s }
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      standard = Standard.build(template)
      synthesized = with_standards_log(runner, "'VAV PFP Boxes' #{operation}") do
        standard.model_add_hvac_system(model, 'VAV PFP Boxes', 'NaturalGas', nil, 'Electricity', zones)
      end
      unless synthesized
        runner.registerError("openstudio-standards failed to add 'VAV PFP Boxes' for #{operation}.")
        return false
      end
      loops = model.getAirLoopHVACs.reject { |air_loop| before.include?(air_loop.handle.to_s) }
      unserved = zones - loops.flat_map(&:thermalZones).uniq
      unless unserved.empty?
        runner.registerError("VAV PFP Boxes #{operation} did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      orphaned_plants = operation == 'replace' ? remove_orphaned_plant_loops(model, loaded_plants) : []
      plants = model.getPlantLoops.reject { |plant_loop| plant_handles.include?(plant_loop.handle.to_s) }
      summary = "Created #{loops.size} VAV PFP Boxes loops and #{plants.size} plant loops for #{zones.size} zones using #{template}."
      summary = "Removed #{affected.size} air loops and #{removed} zone HVAC objects; #{summary} #{plant_note(model, plant_handles, orphaned_plants)}" if operation == 'replace'
      runner.registerFinalCondition(summary)
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("VAV PFP Boxes #{operation} failed: #{e.message}")
      false
    end
  end

  # Log messages that openstudio-standards itself treats as noise when forwarding its log to a runner.
  STANDARDS_LOG_NOISE = ['UseWeatherFile', 'Skipping layer', 'has multiple parents', 'Successive data points',
                         'does not have an Output', 'Prior to OpenStudio 2.6.2'].freeze

  private

  # openstudio-standards reports most synthesis problems through the OpenStudio log and still returns the
  # model, so its return value cannot tell a failed step from a good one. This captures the log while the
  # block runs, forwards warnings to the runner, and reports errors, in which case the synthesis counts as
  # failed and the caller must stop.
  def with_standards_log(runner, label)
    sink = OpenStudio::StringStreamLogSink.new
    sink.setLogLevel(OpenStudio::Warn)
    result = yield
    errors, warnings = sink.logMessages.partition { |message| message.logLevel >= OpenStudio::Error }
    # Every error fails synthesis except two known notices that do not reflect a synthesis problem.
    errors.reject! do |message|
      (message.logChannel == 'openstudio.measure.OSRunner' && message.logMessage.include?('Cannot find current Workflow Step')) ||
        (message.logChannel == 'openstudio.model.YearDescription' && message.logMessage.include?('UseWeatherFile'))
    end
    warnings.reject! do |message|
      message.logChannel.match?(/openstudio\.(measure|Workflow)|runmanager|Translator|setFileExtension/) ||
        STANDARDS_LOG_NOISE.any? { |noise| message.logMessage.include?(noise) }
    end
    warnings.map { |message| "[#{message.logChannel}] #{message.logMessage}" }.uniq.each do |text|
      runner.registerWarning("openstudio-standards #{label}: #{text}")
    end
    errors.map { |message| "[#{message.logChannel}] #{message.logMessage}" }.uniq.each do |text|
      runner.registerError("openstudio-standards #{label}: #{text}")
    end
    result && errors.empty?
  ensure
    sink&.disable
  end

  # Nodes, pipes, pumps, splitters and mixers only move water; anything else on a loop is equipment or a load.
  def plant_equipment?(component)
    return false if component.to_Node.is_initialized || component.to_ConnectorSplitter.is_initialized || component.to_ConnectorMixer.is_initialized

    !component.iddObjectType.valueName.match?(/^OS_(Pipe|Pump|HeaderedPumps)_/)
  end

  # Handles of the plant loops that currently serve at least one demand-side load.
  def loaded_plant_loop_handles(model)
    loaded = model.getPlantLoops.select { |plant_loop| plant_loop.demandComponents.any? { |component| plant_equipment?(component) } }
    loaded.map { |plant_loop| plant_loop.handle.to_s }
  end

  # Removes the loops among `handles` that the replacement left without any demand-side load, together with
  # their supply equipment. PlantLoop#remove on its own leaves a chiller attached to its condenser loop, and
  # removing the chiller can leave that condenser loop without loads in turn, so the pass repeats until
  # nothing more is orphaned. Loops that still serve other zones keep their loads and are not touched.
  def remove_orphaned_plant_loops(model, handles)
    removed = []
    loop do
      orphaned = model.getPlantLoops.select do |plant_loop|
        handles.include?(plant_loop.handle.to_s) && plant_loop.demandComponents.none? { |component| plant_equipment?(component) }
      end
      break if orphaned.empty?

      orphaned.each do |plant_loop|
        removed << plant_loop.name.to_s
        plant_loop.supplyComponents.select { |component| plant_equipment?(component) }.each(&:remove)
        plant_loop.remove
      end
    end
    removed
  end

  # One sentence on what happened to the plant loops that existed before a replacement.
  def plant_note(model, pre_existing_handles, orphaned_names)
    kept = model.getPlantLoops.count { |plant_loop| pre_existing_handles.include?(plant_loop.handle.to_s) }
    note = "Preserved #{kept} pre-existing plant loops."
    note += " Removed #{orphaned_names.size} left without loads: #{orphaned_names.join(', ')}." unless orphaned_names.empty?
    note
  end
end

HvacVavElectricReheat.new.registerWithApplication