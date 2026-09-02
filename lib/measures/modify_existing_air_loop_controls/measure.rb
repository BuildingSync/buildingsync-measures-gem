class ModifyExistingAirLoopControls < OpenStudio::Measure::ModelMeasure
  def name
    'Modify Existing Air Loop Controls'
  end

  def description
    'Updates sizing supply-air temperatures and economizer controls on explicitly named air loops.'
  end

  def modeler_description
    'Performs exact-name matching only. It does not infer HVAC type, add equipment, or alter topology.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_air_loop_names', true)
    names.setDisplayName('Target Air Loop Names')
    names.setDescription('Comma-separated exact OpenStudio air-loop names.')
    args << names

    set_sat = OpenStudio::Measure::OSArgument.makeBoolArgument('set_supply_air_temperatures', true)
    set_sat.setDisplayName('Set Supply Air Temperatures')
    set_sat.setDefaultValue(false)
    args << set_sat

    cooling_sat = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_supply_air_temperature_c', true)
    cooling_sat.setDisplayName('Cooling Supply Air Temperature (C)')
    cooling_sat.setDefaultValue(12.8)
    args << cooling_sat

    heating_sat = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_supply_air_temperature_c', true)
    heating_sat.setDisplayName('Heating Supply Air Temperature (C)')
    heating_sat.setDefaultValue(32.0)
    args << heating_sat

    set_economizer = OpenStudio::Measure::OSArgument.makeBoolArgument('set_economizer', true)
    set_economizer.setDisplayName('Set Economizer')
    set_economizer.setDefaultValue(false)
    args << set_economizer

    types = OpenStudio::StringVector.new
    %w[NoEconomizer FixedDryBulb FixedEnthalpy DifferentialDryBulb DifferentialEnthalpy ElectronicEnthalpy].each do |value|
      types << value
    end
    economizer_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('economizer_control_type', types, true)
    economizer_type.setDisplayName('Economizer Control Type')
    economizer_type.setDefaultValue('FixedDryBulb')
    args << economizer_type

    dry_bulb = OpenStudio::Measure::OSArgument.makeDoubleArgument('economizer_high_limit_dry_bulb_temperature_c', true)
    dry_bulb.setDisplayName('Economizer High Limit Dry Bulb (C)')
    dry_bulb.setDefaultValue(24.0)
    args << dry_bulb

    enthalpy = OpenStudio::Measure::OSArgument.makeDoubleArgument('economizer_high_limit_enthalpy_j_kg', true)
    enthalpy.setDisplayName('Economizer High Limit Enthalpy (J/kg)')
    enthalpy.setDefaultValue(64_000.0)
    args << enthalpy

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    names = runner.getStringArgumentValue('target_air_loop_names', user_arguments)
                  .split(',').map(&:strip).reject(&:empty?).uniq
    if names.empty?
      runner.registerError('At least one target_air_loop_names value is required.')
      return false
    end
    loops = model.getAirLoopHVACs.select { |air_loop| names.include?(air_loop.name.to_s) }
    missing = names - loops.map { |air_loop| air_loop.name.to_s }
    unless missing.empty?
      runner.registerError("Air loops not found: #{missing.join(', ')}")
      return false
    end

    set_sat = runner.getBoolArgumentValue('set_supply_air_temperatures', user_arguments)
    set_economizer = runner.getBoolArgumentValue('set_economizer', user_arguments)
    unless set_sat || set_economizer
      runner.registerAsNotApplicable('Neither supply-air temperatures nor economizer controls were selected.')
      return true
    end

    if set_sat
      cooling_sat = runner.getDoubleArgumentValue('cooling_supply_air_temperature_c', user_arguments)
      heating_sat = runner.getDoubleArgumentValue('heating_supply_air_temperature_c', user_arguments)
      loops.each do |air_loop|
        air_loop.sizingSystem.setCentralCoolingDesignSupplyAirTemperature(cooling_sat)
        air_loop.sizingSystem.setCentralHeatingDesignSupplyAirTemperature(heating_sat)
      end
    end

    if set_economizer
      economizer_type = runner.getStringArgumentValue('economizer_control_type', user_arguments)
      dry_bulb = runner.getDoubleArgumentValue('economizer_high_limit_dry_bulb_temperature_c', user_arguments)
      enthalpy = runner.getDoubleArgumentValue('economizer_high_limit_enthalpy_j_kg', user_arguments)
      loops.each do |air_loop|
        outdoor_air = air_loop.airLoopHVACOutdoorAirSystem
        unless outdoor_air.is_initialized
          runner.registerWarning("Air loop '#{air_loop.name}' has no outdoor-air system; economizer was not changed.")
          next
        end
        controller = outdoor_air.get.getControllerOutdoorAir
        controller.setEconomizerControlType(economizer_type)
        controller.setEconomizerMaximumLimitDryBulbTemperature(dry_bulb) if %w[FixedDryBulb DifferentialDryBulb].include?(economizer_type)
        controller.setEconomizerMaximumLimitEnthalpy(enthalpy) if %w[FixedEnthalpy DifferentialEnthalpy ElectronicEnthalpy].include?(economizer_type)
      end
    end

    runner.registerFinalCondition("Updated controls on #{loops.size} explicitly named air loops.")
    true
  end
end

ModifyExistingAirLoopControls.new.registerWithApplication
