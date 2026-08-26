class CreateChilledBeamHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Create Chilled-Beam HVAC'
  def description = 'Adds four-pipe chilled-beam terminals, primary outdoor-air delivery, and supporting plants to unserved target zones.'
  def modeler_description = 'Uses temporary standards fan coils to establish plants, replaces them with four-pipe beam terminals, and constructs a dedicated primary-air loop.'

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
    template.setDescription('openstudio-standards template used to construct supporting hot- and chilled-water plants.')
    template.setDefaultValue('90.1-2019')
    args << template
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested = runner.getStringArgumentValue('target_zone_names', user_arguments).split(',').map(&:strip).reject(&:empty?).uniq
    template = runner.getStringArgumentValue('standards_template', user_arguments)
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
      runner.registerError("Chilled-beam creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      plant_handles = model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }
      fan_coil_handles = model.getZoneHVACFourPipeFanCoils.map { |unit| unit.handle.to_s }
      Standard.build(template).model_add_hvac_system(model, 'Fan Coil', 'NaturalGas', nil, 'Electricity', zones)
      temporary_units = model.getZoneHVACFourPipeFanCoils.reject { |unit| fan_coil_handles.include?(unit.handle.to_s) }
      heating_loops = temporary_units.filter_map do |unit|
        coil = unit.heatingCoil.to_CoilHeatingWater
        coil.get.plantLoop.get if coil.is_initialized && coil.get.plantLoop.is_initialized
      end.uniq
      cooling_loops = temporary_units.filter_map do |unit|
        coil = unit.coolingCoil.to_CoilCoolingWater
        coil.get.plantLoop.get if coil.is_initialized && coil.get.plantLoop.is_initialized
      end.uniq
      unless temporary_units.size == zones.size && heating_loops.size == 1 && cooling_loops.size == 1
        runner.registerError('Chilled-beam plant synthesis did not produce one shared heating loop and one shared cooling loop.')
        return false
      end
      temporary_units.each(&:remove)

      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName('Chilled-Beam Primary Air Loop')
      air_loop.sizingSystem.setTypeofLoadtoSizeOn('VentilationRequirement')
      controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
      OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller).addToNode(air_loop.supplyInletNode)
      OpenStudio::Model::FanSystemModel.new(model).addToNode(air_loop.supplyOutletNode)
      terminals = zones.map do |zone|
        cooling_coil = OpenStudio::Model::CoilCoolingFourPipeBeam.new(model)
        heating_coil = OpenStudio::Model::CoilHeatingFourPipeBeam.new(model)
        terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeFourPipeBeam.new(model)
        terminal.setName("#{zone.name} Four-Pipe Chilled Beam")
        terminal.setCoolingCoil(cooling_coil)
        terminal.setHeatingCoil(heating_coil)
        cooling_loops.first.addDemandBranchForComponent(cooling_coil)
        heating_loops.first.addDemandBranchForComponent(heating_coil)
        air_loop.addBranchForZone(zone, terminal)
        terminal
      end
      missing_zones = zones.reject do |zone|
        zone.airLoopHVACTerminal.is_initialized && terminals.include?(zone.airLoopHVACTerminal.get)
      end
      unless missing_zones.empty?
        runner.registerError("Chilled-beam creation did not serve: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      created_plants = model.getPlantLoops.count { |plant_loop| !plant_handles.include?(plant_loop.handle.to_s) }
      runner.registerFinalCondition("Created one primary-air loop, #{terminals.size} four-pipe chilled beams, and #{created_plants} plant loops using #{template}.")
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Chilled-beam creation failed: #{e.message}")
      false
    end
  end
end

CreateChilledBeamHvac.new.registerWithApplication
