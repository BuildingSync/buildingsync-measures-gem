class CreateFourPipeFanCoilHvac < OpenStudio::Measure::ModelMeasure
  def name
    'Create Four-Pipe Fan Coil HVAC'
  end

  def description
    'Adds four-pipe fan-coil units and their required plant infrastructure to unserved target zones.'
  end

  def modeler_description
    'Uses openstudio-standards to create Fan Coil systems. Fails when selected zones already have zone HVAC or an air-loop connection.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    target_zone_names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', false)
    target_zone_names.setDisplayName('Target Zone Names')
    target_zone_names.setDescription('Comma-separated exact thermal-zone names. Blank selects all thermal zones.')
    target_zone_names.setDefaultValue('')
    args << target_zone_names

    templates = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| templates << value }
    standards_template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', templates, true)
    standards_template.setDisplayName('Standards Template')
    standards_template.setDescription('openstudio-standards template used to construct the four-pipe fan-coil system.')
    standards_template.setDefaultValue('90.1-2019')
    args << standards_template

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested_names = runner.getStringArgumentValue('target_zone_names', user_arguments)
                            .split(',').map(&:strip).reject(&:empty?).uniq
    standards_template = runner.getStringArgumentValue('standards_template', user_arguments)
    zones = requested_names.empty? ? model.getThermalZones.to_a : model.getThermalZones.select do |zone|
      requested_names.include?(zone.name.to_s)
    end
    missing_names = requested_names - zones.map { |zone| zone.name.to_s }
    unless missing_names.empty?
      runner.registerError("Thermal zones not found: #{missing_names.join(', ')}")
      return false
    end
    if zones.empty?
      runner.registerError('No target thermal zones were found.')
      return false
    end

    served_by_air_loop = model.getAirLoopHVACs.flat_map(&:thermalZones).uniq
    conflicts = zones.select { |zone| !zone.equipment.empty? || served_by_air_loop.include?(zone) }
    unless conflicts.empty?
      runner.registerError("Four-pipe fan-coil creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end

    begin
      require 'openstudio-standards'
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
        runner.registerError("Four-pipe fan-coil creation did not produce equipment for: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end

      runner.registerFinalCondition(
        "Created #{created_units.size} four-pipe fan-coil units and #{created_plants.size} plant loops " \
        "for #{zones.size} zones using #{standards_template}."
      )
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Four-pipe fan-coil creation failed: #{e.message}")
      false
    end
  end
end

CreateFourPipeFanCoilHvac.new.registerWithApplication
