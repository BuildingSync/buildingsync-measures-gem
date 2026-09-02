class HvacChilledBeam < OpenStudio::Measure::ModelMeasure
  def name = 'Chilled-Beam HVAC'
  def description = 'Creates chilled-beam systems in unserved zones or replaces HVAC dedicated to selected zones.'
  def modeler_description = 'Synthesizes supporting plants with temporary fan coils, then installs four-pipe beams and a primary-air loop.'

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
    template.setDescription('openstudio-standards template used to construct supporting hot- and chilled-water plants.')
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
        runner.registerError("Chilled-beam creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
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
      plant_handles = model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }
      fan_coil_handles = model.getZoneHVACFourPipeFanCoils.map { |unit| unit.handle.to_s }
      template = runner.getStringArgumentValue('standards_template', user_arguments)
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
      unserved = zones.reject { |zone| zone.airLoopHVACTerminal.is_initialized && terminals.include?(zone.airLoopHVACTerminal.get) }
      unless unserved.empty?
        runner.registerError("Chilled-beam #{operation} did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      created_plants = model.getPlantLoops.count { |plant_loop| !plant_handles.include?(plant_loop.handle.to_s) }
      summary = "Created one primary-air loop, #{terminals.size} chilled beams, and #{created_plants} plant loops using #{template}."
      summary = "Removed #{affected.size} air loops and #{removed} zone HVAC objects; #{summary} Preserved #{preserved_plants} existing plant loops." if operation == 'replace'
      runner.registerFinalCondition(summary)
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Chilled-beam #{operation} failed: #{e.message}")
      false
    end
  end
end

HvacChilledBeam.new.registerWithApplication