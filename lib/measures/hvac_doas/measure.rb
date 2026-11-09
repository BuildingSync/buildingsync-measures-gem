class HvacDoas < OpenStudio::Measure::ModelMeasure
  def name = 'Dedicated Outdoor Air System HVAC'
  def description = 'Adds a dedicated outdoor-air system to zones without air-loop service, or replaces the air loops serving selected zones. Zone equipment is kept.'
  def modeler_description = 'Directly constructs one DOAS topology; replacement rejects partial shared-loop removal and preserves plants.'

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
      conflicts = zones.select { |zone| affected.any? { |air_loop| air_loop.thermalZones.include?(zone) } }
      unless conflicts.empty?
        runner.registerError("DOAS creation requires zones without air-loop service; zone equipment is kept. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
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

    # Direct-to-zone DOAS: the DOAS terminal is the only outdoor-air source, so zone units only recirculate.
    zero_outdoor_air = lambda do |equipment|
      %w[ZoneHVACPackagedTerminalAirConditioner ZoneHVACPackagedTerminalHeatPump ZoneHVACWaterToAirHeatPump ZoneHVACTerminalUnitVariableRefrigerantFlow ZoneHVACFourPipeFanCoil].each do |type|
        unit = equipment.public_send("to_#{type}")
        next unless unit.is_initialized

        %w[setOutdoorAirFlowRateDuringCoolingOperation setOutdoorAirFlowRateDuringHeatingOperation setOutdoorAirFlowRateWhenNoCoolingorHeatingisNeeded setMaximumOutdoorAirFlowRate].each do |setter|
          unit.get.public_send(setter, 0.0) if unit.get.respond_to?(setter)
        end
        return true
      end
      false
    end

    begin
      preserved_plants = model.getPlantLoops.size
      affected.each(&:remove) if operation == 'replace'
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName('Dedicated Outdoor Air System')
      air_loop.sizingSystem.setTypeofLoadtoSizeOn('VentilationRequirement')
      controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
      OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller).addToNode(air_loop.supplyInletNode)
      OpenStudio::Model::FanSystemModel.new(model).addToNode(air_loop.supplyOutletNode)
      zones.each do |zone|
        terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, model.alwaysOnDiscreteSchedule)
        terminal.setName("#{zone.name} DOAS Terminal")
        air_loop.addBranchForZone(zone, terminal)
        zone.setCoolingPriority(terminal, 1)
        zone.setHeatingPriority(terminal, 1)
      end
      unserved = zones - air_loop.thermalZones.to_a
      unless unserved.empty?
        runner.registerError("DOAS #{operation} did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      summary = "Created one DOAS loop for #{zones.size} zones using workflow template #{template}."
      summary = "Removed #{affected.size} air loops and kept existing zone equipment; #{summary} Preserved #{preserved_plants} plant loops." if operation == 'replace'
      zeroed = zones.sum { |zone| zone.equipment.count { |equipment| zero_outdoor_air.call(equipment) } }
      runner.registerInfo("Set outdoor air to 0 on #{zeroed} existing zone units; the DOAS supplies ventilation directly to each zone.") if zeroed.positive?
      runner.registerFinalCondition(summary)
      true
    rescue StandardError => e
      runner.registerError("DOAS #{operation} failed: #{e.message}")
      false
    end
  end
end

HvacDoas.new.registerWithApplication