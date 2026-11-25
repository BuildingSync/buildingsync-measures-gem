require 'json'

# Heating from one source plus cooling-only PTACs in the same zones, created in one step. Chaining a
# heating measure and the PTAC measure does not work because each one rejects zones the other has served.
class HvacHeatingWithTerminalCooling < OpenStudio::Measure::ModelMeasure
  HEATING_SOURCES = %w[central_gas_furnace hot_water_baseboard electric_baseboard hot_water_ptac_coil].freeze
  BOILER_FUELS = %w[NaturalGas Electricity FuelOilNo2 Propane].freeze

  def name = 'Heating With Terminal Cooling HVAC'
  def description = 'Creates a heating source and cooling-only PTACs (single-speed DX) together in unserved zones.'
  def modeler_description = 'heating_source central_gas_furnace adds one shared constant-volume gas-furnace air loop that ' \
                            'also supplies outdoor air, with PTACs that do not ventilate; hot_water_baseboard and ' \
                            'electric_baseboard add a baseboard per zone; hot_water_ptac_coil puts a hot-water coil in each ' \
                            'PTAC. Hot-water options add one boiler loop. Otherwise each PTAC heating coil is a ' \
                            'zero-capacity, always-off placeholder.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    args << choice('operation', 'Operation', %w[create], 'create',
                   'Only create is supported; the zones must be unserved apart from dedicated outdoor-air systems.')
    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', false)
    names.setDisplayName('Target Zone Names')
    names.setDescription('Comma-separated exact thermal-zone names, or a JSON array of exact names (for names containing commas). Blank selects all zones.')
    names.setDefaultValue('')
    args << names
    args << choice('standards_template', 'Standards Template',
                   ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010',
                    '90.1-2013', '90.1-2016', '90.1-2019'], '90.1-2019')
    args << choice('heating_source', 'Heating Source', HEATING_SOURCES, 'central_gas_furnace',
                   'Heating that serves the zones alongside the cooling-only PTACs.')
    args << choice('boiler_fuel', 'Boiler Fuel', BOILER_FUELS, 'NaturalGas',
                   'Boiler fuel for hot_water_baseboard and hot_water_ptac_coil; ignored otherwise.')
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    text = runner.getStringArgumentValue('target_zone_names', user_arguments).strip
    begin
      requested = text.start_with?('[') ? JSON.parse(text) : text.split(',').map(&:strip)
    rescue JSON::ParserError
      requested = nil
    end
    unless requested.is_a?(Array) && requested.all? { |zone_name| zone_name.is_a?(String) }
      runner.registerError('target_zone_names must be comma-separated names or a JSON array of strings.')
      return false
    end
    requested = requested.reject { |zone_name| zone_name.strip.empty? }.uniq
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
    conflicts = zones.select do |zone|
      zone.equipment.any? { |equipment| !doas_handles.include?(equipment.handle.to_s) } ||
        affected.any? { |air_loop| air_loop.thermalZones.include?(zone) }
    end
    unless conflicts.empty?
      runner.registerError("Heating with terminal cooling creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end

    source = runner.getStringArgumentValue('heating_source', user_arguments)
    fuel = runner.getStringArgumentValue('boiler_fuel', user_arguments)
    template = runner.getStringArgumentValue('standards_template', user_arguments)
    hot_water = source.start_with?('hot_water')
    begin
      require 'openstudio-standards'
      standard = Standard.build(template)
      plant_handles = model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }
      synthesized = with_standards_log(runner, "'#{source}' create") do
        hw_loop = standard.model_add_hw_loop(model, fuel) if hot_water
        heating = case source
                  when 'central_gas_furnace' then add_central_furnace(standard, model, zones)
                  when 'hot_water_baseboard' then standard.model_add_baseboard(model, zones, hot_water_loop: hw_loop)
                  when 'electric_baseboard' then standard.model_add_baseboard(model, zones)
                  else true
                  end
        # The furnace loop supplies outdoor air; otherwise the PTACs ventilate unless a DOAS already does.
        ptacs = standard.model_add_ptac(model, zones, cooling_type: 'Single Speed DX AC',
                                                      heating_type: source == 'hot_water_ptac_coil' ? 'Water' : nil,
                                                      hot_water_loop: hw_loop, fan_type: 'ConstantVolume',
                                                      ventilation: source != 'central_gas_furnace' && doas_loops.empty?)
        heating && ptacs && prioritize(zones, source)
      end
      unless synthesized
        runner.registerError("openstudio-standards failed to add '#{source}' with terminal cooling.")
        return false
      end
      served = model.getZoneHVACPackagedTerminalAirConditioners.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized }
      unserved = zones - served
      unless unserved.empty?
        runner.registerError("Terminal cooling was not produced for: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      plants = model.getPlantLoops.count { |plant_loop| !plant_handles.include?(plant_loop.handle.to_s) }
      runner.registerFinalCondition("Created #{source} heating and #{zones.size} cooling-only PTACs with #{plants} plant loops " \
                                    "for #{zones.size} zones using #{template}.")
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Heating with terminal cooling create failed: #{e.message}")
      false
    end
  end

  # Log messages that openstudio-standards itself treats as noise when forwarding its log to a runner.
  STANDARDS_LOG_NOISE = ['UseWeatherFile', 'Skipping layer', 'has multiple parents', 'Successive data points',
                         'does not have an Output', 'Prior to OpenStudio 2.6.2'].freeze

  private

  def choice(name, display_name, values, default, description = nil)
    choices = OpenStudio::StringVector.new
    values.each { |value| choices << value }
    argument = OpenStudio::Measure::OSArgument.makeChoiceArgument(name, choices, true)
    argument.setDisplayName(display_name)
    argument.setDescription(description) if description
    argument.setDefaultValue(default)
    argument
  end

  # One heating-only constant-volume air loop for all zones: outdoor-air system, gas coil, fan. The supply
  # temperature follows the coldest zone; the coil only heats, so mixed air passes through otherwise.
  def add_central_furnace(standard, model, zones)
    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName('Central Gas Furnace')
    sizing = air_loop.sizingSystem
    sizing.setTypeofLoadtoSizeOn('Sensible')
    sizing.setCentralHeatingDesignSupplyAirTemperature(40.0)
    sizing.setCentralCoolingDesignSupplyAirTemperature(12.8)
    controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
    controller.setName('Central Gas Furnace OA Controller')
    controller.setEconomizerControlType('NoEconomizer')
    controller.autosizeMinimumOutdoorAirFlowRate
    controller.autosizeMaximumOutdoorAirFlowRate
    OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller).addToNode(air_loop.supplyInletNode)
    standard.create_coil_heating_gas(model, air_loop_node: air_loop.supplyOutletNode, name: 'Central Gas Furnace Htg Coil')
    fan = OpenStudio::Model::FanConstantVolume.new(model)
    fan.setName('Central Gas Furnace Fan')
    fan.addToNode(air_loop.supplyOutletNode)
    setpoint = OpenStudio::Model::SetpointManagerColdest.new(model)
    setpoint.setMinimumSetpointTemperature(12.8)
    setpoint.setMaximumSetpointTemperature(40.0)
    setpoint.addToNode(air_loop.supplyOutletNode)
    zones.each do |zone|
      terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, model.alwaysOnDiscreteSchedule)
      terminal.setName("#{zone.name} Furnace Diffuser")
      return false unless air_loop.addBranchForZone(zone, terminal.to_StraightComponent)
    end
    true
  end

  # PTACs take cooling first; the heating source takes heating first.
  def prioritize(zones, source)
    zones.each do |zone|
      ptac = zone.equipment.find { |equipment| equipment.to_ZoneHVACPackagedTerminalAirConditioner.is_initialized }
      return false unless ptac

      heater = zone.equipment.find do |equipment|
        source == 'central_gas_furnace' ? equipment.to_AirTerminalSingleDuctConstantVolumeNoReheat.is_initialized : equipment.iddObjectType.valueName.include?('Baseboard')
      end
      next unless heater

      zone.setCoolingPriority(ptac, 1)
      zone.setHeatingPriority(heater, 1)
    end
    true
  end

  # Same contract as the hvac_ptac measure: forwards standards warnings and fails on standards errors.
  def with_standards_log(runner, label)
    sink = OpenStudio::StringStreamLogSink.new
    sink.setLogLevel(OpenStudio::Warn)
    result = yield
    errors, warnings = sink.logMessages.partition { |message| message.logLevel >= OpenStudio::Error }
    errors.reject! do |message|
      (message.logChannel == 'openstudio.measure.OSRunner' && message.logMessage.include?('Cannot find current Workflow Step')) ||
        (message.logChannel == 'openstudio.model.YearDescription' && message.logMessage.include?('UseWeatherFile'))
    end
    warnings.reject! do |message|
      message.logChannel.match?(/openstudio\.(measure|Workflow)|runmanager|Translator|setFileExtension/) ||
        STANDARDS_LOG_NOISE.any? { |noise| message.logMessage.include?(noise) }
    end
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
end

HvacHeatingWithTerminalCooling.new.registerWithApplication
