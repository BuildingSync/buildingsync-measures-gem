class ReplaceWithFourPipeFanCoilHvac < OpenStudio::Measure::ModelMeasure
  def name
    'Replace HVAC with Four-Pipe Fan Coils'
  end

  def description
    'Removes HVAC dedicated to selected zones and installs four-pipe fan-coil systems.'
  end

  def modeler_description
    'Rejects partial removal of shared air loops, preserves existing plant loops, and creates fan-coil equipment plus required new plants with openstudio-standards.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    target_zone_names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', true)
    target_zone_names.setDisplayName('Target Zone Names')
    target_zone_names.setDescription('Comma-separated exact thermal-zone names to replace. At least one name is required.')
    args << target_zone_names

    templates = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| templates << value }
    standards_template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', templates, true)
    standards_template.setDisplayName('Standards Template')
    standards_template.setDescription('openstudio-standards template used to construct the replacement fan-coil system.')
    standards_template.setDefaultValue('90.1-2019')
    args << standards_template

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested_names = runner.getStringArgumentValue('target_zone_names', user_arguments)
                            .split(',').map(&:strip).reject(&:empty?).uniq
    if requested_names.empty?
      runner.registerError('target_zone_names must contain at least one exact thermal-zone name.')
      return false
    end
    standards_template = runner.getStringArgumentValue('standards_template', user_arguments)
    zones = model.getThermalZones.select { |zone| requested_names.include?(zone.name.to_s) }
    missing_names = requested_names - zones.map { |zone| zone.name.to_s }
    unless missing_names.empty?
      runner.registerError("Thermal zones not found: #{missing_names.join(', ')}")
      return false
    end

    affected_air_loops = model.getAirLoopHVACs.select do |air_loop|
      (air_loop.thermalZones.to_a & zones).any?
    end
    shared_air_loops = affected_air_loops.select do |air_loop|
      (air_loop.thermalZones.to_a - zones).any?
    end
    unless shared_air_loops.empty?
      details = shared_air_loops.map do |air_loop|
        remaining = air_loop.thermalZones.to_a - zones
        "#{air_loop.name}: also serves #{remaining.map { |zone| zone.name.to_s }.join(', ')}"
      end
      runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      preserved_plant_count = model.getPlantLoops.size
      removed_zone_equipment = zones.sum do |zone|
        equipment = zone.equipment.to_a
        equipment.each(&:remove)
        equipment.size
      end
      affected_air_loops.each(&:remove)

      before_unit_handles = model.getZoneHVACFourPipeFanCoils.map { |unit| unit.handle.to_s }
      before_plant_handles = model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }
      Standard.build(standards_template).model_add_hvac_system(
        model, 'Fan Coil', 'NaturalGas', nil, 'Electricity', zones
      )
      created_units = model.getZoneHVACFourPipeFanCoils.reject do |unit|
        before_unit_handles.include?(unit.handle.to_s)
      end
      created_plants = model.getPlantLoops.reject do |plant_loop|
        before_plant_handles.include?(plant_loop.handle.to_s)
      end
      created_zones = created_units.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized }
      missing_zones = zones - created_zones
      unless missing_zones.empty?
        runner.registerError("Four-pipe fan-coil replacement did not produce equipment for: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end

      runner.registerFinalCondition(
        "Removed #{affected_air_loops.size} dedicated air loops and #{removed_zone_equipment} zone HVAC objects; " \
        "created #{created_units.size} fan-coil units and #{created_plants.size} plant loops. " \
        "Preserved #{preserved_plant_count} pre-existing plant loops."
      )
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Four-pipe fan-coil replacement failed: #{e.message}")
      false
    end
  end
end

ReplaceWithFourPipeFanCoilHvac.new.registerWithApplication
