class HvacFourPipeFanCoil < OpenStudio::Measure::ModelMeasure
  def name = 'Four-Pipe Fan Coil HVAC'
  def description = 'Creates four-pipe fan coils in unserved zones or replaces HVAC dedicated to selected zones.'
  def modeler_description = 'Uses one synthesis path for both operations; replacement rejects partial shared-air-loop removal and preserves pre-existing plant loops.'

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
    templates = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| templates << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', templates, true)
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

    affected = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }
    if operation == 'create'
      conflicts = zones.select { |zone| !zone.equipment.empty? || affected.any? { |air_loop| air_loop.thermalZones.include?(zone) } }
      unless conflicts.empty?
        runner.registerError("Four-pipe fan-coil creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
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
      unit_handles = model.getZoneHVACFourPipeFanCoils.map { |unit| unit.handle.to_s }
      plant_handles = model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      Standard.build(template).model_add_hvac_system(model, 'Fan Coil', 'NaturalGas', nil, 'Electricity', zones)
      units = model.getZoneHVACFourPipeFanCoils.reject { |unit| unit_handles.include?(unit.handle.to_s) }
      plants = model.getPlantLoops.reject { |plant_loop| plant_handles.include?(plant_loop.handle.to_s) }
      served = units.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized }
      unserved = zones - served
      unless unserved.empty?
        runner.registerError("Four-pipe fan-coil #{operation} did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      summary = "Created #{units.size} four-pipe fan-coil units and #{plants.size} plant loops for #{zones.size} zones using #{template}."
      summary = "Removed #{affected.size} air loops and #{removed} zone HVAC objects; #{summary} Preserved #{preserved_plants} pre-existing plant loops." if operation == 'replace'
      runner.registerFinalCondition(summary)
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Four-pipe fan-coil #{operation} failed: #{e.message}")
      false
    end
  end
end

HvacFourPipeFanCoil.new.registerWithApplication