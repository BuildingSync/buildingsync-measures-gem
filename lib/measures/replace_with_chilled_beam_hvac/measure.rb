class ReplaceWithChilledBeamHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Replace HVAC with Chilled Beams'
  def description = 'Replaces HVAC dedicated to selected zones with four-pipe chilled beams and a primary outdoor-air loop.'
  def modeler_description = 'Rejects partial shared-loop removal, preserves existing plants, creates new supporting plants, and installs four-pipe beam terminals.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', true)
    names.setDisplayName('Target Zone Names')
    names.setDescription('Comma-separated exact thermal-zone names to replace.')
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
    if requested.empty?
      runner.registerError('target_zone_names must contain at least one exact thermal-zone name.')
      return false
    end
    template = runner.getStringArgumentValue('standards_template', user_arguments)
    zones = model.getThermalZones.select { |zone| requested.include?(zone.name.to_s) }
    missing = requested - zones.map { |zone| zone.name.to_s }
    unless missing.empty?
      runner.registerError("Thermal zones not found: #{missing.join(', ')}")
      return false
    end
    affected = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }
    shared = affected.select { |air_loop| (air_loop.thermalZones.to_a - zones).any? }
    unless shared.empty?
      details = shared.map { |air_loop| "#{air_loop.name}: also serves #{(air_loop.thermalZones.to_a - zones).map { |zone| zone.name.to_s }.join(', ')}" }
      runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      preserved_plants = model.getPlantLoops.size
      removed = zones.sum do |zone|
        equipment = zone.equipment.to_a
        equipment.each(&:remove)
        equipment.size
      end
      affected.each(&:remove)
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
      missing_zones = zones.reject { |zone| zone.airLoopHVACTerminal.is_initialized && terminals.include?(zone.airLoopHVACTerminal.get) }
      unless missing_zones.empty?
        runner.registerError("Chilled-beam replacement did not serve: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      created_plants = model.getPlantLoops.count { |plant_loop| !plant_handles.include?(plant_loop.handle.to_s) }
      runner.registerFinalCondition(
        "Removed #{affected.size} air loops and #{removed} zone HVAC objects; created one primary-air loop, " \
        "#{terminals.size} chilled beams, and #{created_plants} plants; preserved #{preserved_plants} existing plants."
      )
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Chilled-beam replacement failed: #{e.message}")
      false
    end
  end
end

ReplaceWithChilledBeamHvac.new.registerWithApplication
