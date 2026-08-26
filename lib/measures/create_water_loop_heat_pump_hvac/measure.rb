class CreateWaterLoopHeatPumpHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Create Water-Loop Heat Pump HVAC'
  def description = 'Adds water-to-air heat pumps and supporting water-loop infrastructure to unserved target zones.'
  def modeler_description = 'Uses openstudio-standards Water Source Heat Pumps and verifies newly created zone-unit coverage.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', false)
    names.setDisplayName('Target Zone Names')
    names.setDescription('Comma-separated exact thermal-zone names. Blank selects all thermal zones.')
    names.setDefaultValue('')
    args << names
    choices = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| choices << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', choices, true)
    template.setDisplayName('Standards Template')
    template.setDescription('openstudio-standards template used to construct water-source heat pumps.')
    template.setDefaultValue('90.1-2019')
    args << template
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested = runner.getStringArgumentValue('target_zone_names', user_arguments).split(',').map(&:strip).reject(&:empty?).uniq
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
    served = model.getAirLoopHVACs.flat_map(&:thermalZones).uniq
    conflicts = zones.select { |zone| !zone.equipment.empty? || served.include?(zone) }
    unless conflicts.empty?
      runner.registerError("Water-loop heat-pump creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      before_units = model.getZoneHVACWaterToAirHeatPumps.map { |unit| unit.handle.to_s }
      before_plants = model.getPlantLoops.map { |loop| loop.handle.to_s }
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      Standard.build(template).model_add_hvac_system(model, 'Water Source Heat Pumps', 'NaturalGas', nil, 'Electricity', zones)
      created = model.getZoneHVACWaterToAirHeatPumps.reject { |unit| before_units.include?(unit.handle.to_s) }
      plants = model.getPlantLoops.reject { |loop| before_plants.include?(loop.handle.to_s) }
      covered = created.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized }
      unserved = zones - covered
      unless unserved.empty?
        runner.registerError("Water-loop heat-pump creation did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      runner.registerFinalCondition("Created #{created.size} water-to-air heat pumps and #{plants.size} plant loops for #{zones.size} zones using #{template}.")
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Water-loop heat-pump creation failed: #{e.message}")
      false
    end
  end
end

CreateWaterLoopHeatPumpHvac.new.registerWithApplication
