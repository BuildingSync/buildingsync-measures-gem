class HvacVentilationOnly < OpenStudio::Measure::ModelMeasure
  def name = 'Ventilation-Only HVAC'
  def description = 'Creates ventilation-only air systems in unserved zones or replaces HVAC dedicated to selected zones.'
  def modeler_description = 'Directly constructs one ventilation-only topology; replacement rejects partial shared-loop removal and preserves plants.'

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
    template.setDescription('Workflow template recorded for consistency; direct construction does not query standards data.')
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
    affected = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }
    if operation == 'create'
      conflicts = zones.select { |zone| !zone.equipment.empty? || affected.any? { |air_loop| air_loop.thermalZones.include?(zone) } }
      unless conflicts.empty?
        runner.registerError("Ventilation-only creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
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
      preserved_plants = model.getPlantLoops.size
      removed = 0
      if operation == 'replace'
        removed = zones.sum do |zone|
          equipment = zone.equipment.to_a
          equipment.each(&:remove)
          equipment.size
        end
        affected.each(&:remove)
      end
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName('Ventilation Only Air Loop')
      controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
      OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller).addToNode(air_loop.supplyInletNode)
      OpenStudio::Model::FanSystemModel.new(model).addToNode(air_loop.supplyOutletNode)
      zones.each { |zone| air_loop.addBranchForZone(zone) }
      unserved = zones - air_loop.thermalZones.to_a
      unless unserved.empty?
        runner.registerError("Ventilation-only #{operation} did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      summary = "Created one ventilation-only loop for #{zones.size} zones using workflow template #{template}."
      summary = "Removed #{affected.size} air loops and #{removed} zone HVAC objects; #{summary} Preserved #{preserved_plants} plant loops." if operation == 'replace'
      runner.registerFinalCondition(summary)
      true
    rescue StandardError => e
      runner.registerError("Ventilation-only #{operation} failed: #{e.message}")
      false
    end
  end
end

HvacVentilationOnly.new.registerWithApplication