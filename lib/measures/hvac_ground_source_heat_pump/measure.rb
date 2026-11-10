class HvacGroundSourceHeatPump < OpenStudio::Measure::ModelMeasure
  def name = 'Ground-Source Heat Pump HVAC'
  def description = 'Creates ground-source heat pumps in unserved zones or replaces HVAC dedicated to selected zones.'
  def modeler_description = 'Uses one Ground Source Heat Pumps synthesis path; replacement rejects partial shared-loop removal and removes pre-existing plant loops left without loads.'

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
    names.setDescription('Comma-separated exact thermal-zone names. Blank selects all zones for create; replace requires explicit names.')
    names.setDefaultValue('')
    args << names
    choices = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| choices << value }
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
    requested = runner.getStringArgumentValue('target_zone_names', user_arguments).split(',').map(&:strip).reject(&:empty?).uniq
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
    dedicated_outdoor_air = lambda do |air_loop|
      air_loop.sizingSystem.typeofLoadtoSizeOn == 'VentilationRequirement' &&
        air_loop.demandComponents.count { |component| component.to_AirTerminalSingleDuctConstantVolumeNoReheat.is_initialized } == air_loop.thermalZones.size
    end
    doas_loops, affected = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }.partition(&dedicated_outdoor_air)
    doas_handles = doas_loops.flat_map { |air_loop| air_loop.demandComponents.map { |component| component.handle.to_s } }
    zone_equipment = ->(zone) { zone.equipment.reject { |equipment| doas_handles.include?(equipment.handle.to_s) } }
    if operation == 'create'
      conflicts = zones.select { |zone| !zone_equipment.call(zone).empty? || affected.any? { |air_loop| air_loop.thermalZones.include?(zone) } }
      unless conflicts.empty?
        runner.registerError("Ground-source heat-pump creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
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
        removed = zones.sum do |zone|
          equipment = zone_equipment.call(zone).to_a
          equipment.each(&:remove)
          equipment.size
        end
        affected.each(&:remove)
      end
      unit_handles = model.getZoneHVACWaterToAirHeatPumps.map { |unit| unit.handle.to_s }
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      standard = Standard.build(template)
      synthesized = with_standards_log(runner, "'Ground Source Heat Pumps' #{operation}") do
        standard.model_add_hvac_system(model, 'Ground Source Heat Pumps', 'NaturalGas', nil, 'Electricity', zones)
      end
      unless synthesized
        runner.registerError("openstudio-standards failed to add 'Ground Source Heat Pumps' for #{operation}.")
        return false
      end
      units = model.getZoneHVACWaterToAirHeatPumps.reject { |unit| unit_handles.include?(unit.handle.to_s) }
      served = units.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized }
      unserved = zones - served
      unless unserved.empty?
        runner.registerError("Ground-source heat-pump #{operation} did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      orphaned_plants = operation == 'replace' ? remove_orphaned_plant_loops(model, loaded_plants) : []
      plants = model.getPlantLoops.reject { |plant_loop| plant_handles.include?(plant_loop.handle.to_s) }
      summary = "Created #{units.size} ground-source heat pumps and #{plants.size} plant loops for #{zones.size} zones using #{template}."
      summary = "Removed #{affected.size} air loops and #{removed} zone HVAC objects; #{summary} #{plant_note(model, plant_handles, orphaned_plants)}" if operation == 'replace'
      runner.registerFinalCondition(summary)
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Ground-source heat-pump #{operation} failed: #{e.message}")
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
    messages = sink.logMessages.reject do |message|
      message.logChannel.match?(/openstudio\.(measure|Workflow)|runmanager|Translator|setFileExtension/) ||
        STANDARDS_LOG_NOISE.any? { |noise| message.logMessage.include?(noise) }
    end
    errors, warnings = messages.partition { |message| message.logLevel >= OpenStudio::Error }
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

HvacGroundSourceHeatPump.new.registerWithApplication