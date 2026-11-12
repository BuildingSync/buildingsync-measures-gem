class ModifyExistingHvacEquipmentEfficiencies < OpenStudio::Measure::ModelMeasure
  METRICS = %w[
    dx_cooling_cop dx_heating_cop gas_burner_efficiency electric_heating_efficiency
    water_to_air_cooling_cop water_to_air_heating_cop vrf_cooling_cop vrf_heating_cop
  ].freeze

  def name
    'Modify Existing HVAC Equipment Efficiencies'
  end

  def description
    'Sets one efficiency property on explicitly named existing HVAC components or equipment.'
  end

  def modeler_description
    'Matches exact OpenStudio object names and applies only the selected supported setter. It never adds, removes, or infers HVAC systems.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_object_names', true)
    names.setDisplayName('Target Object Names')
    names.setDescription('Comma-separated exact OpenStudio component or equipment names.')
    args << names

    metrics = OpenStudio::StringVector.new
    METRICS.each { |metric| metrics << metric }
    metric = OpenStudio::Measure::OSArgument.makeChoiceArgument('efficiency_metric', metrics, true)
    metric.setDisplayName('Efficiency Metric')
    metric.setDefaultValue('dx_cooling_cop')
    args << metric

    value = OpenStudio::Measure::OSArgument.makeDoubleArgument('efficiency_value', true)
    value.setDisplayName('Efficiency Value')
    value.setDescription('COP or fractional efficiency, according to efficiency_metric.')
    value.setDefaultValue(3.5)
    args << value

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    names = runner.getStringArgumentValue('target_object_names', user_arguments)
                  .split(',').map(&:strip).reject(&:empty?).uniq
    if names.empty?
      runner.registerError('At least one target_object_names value is required.')
      return false
    end
    metric = runner.getStringArgumentValue('efficiency_metric', user_arguments)
    value = runner.getDoubleArgumentValue('efficiency_value', user_arguments)
    if value <= 0.0 || (%w[gas_burner_efficiency electric_heating_efficiency].include?(metric) && value > 1.0)
      runner.registerError('COP values must be greater than zero; fractional efficiencies must be in (0, 1].')
      return false
    end

    objects = model.getModelObjects.select do |object|
      object.name.is_initialized && names.include?(object.name.get)
    end
    found_names = objects.map { |object| object.name.get }.uniq
    missing = names - found_names
    unless missing.empty?
      runner.registerError("OpenStudio objects not found: #{missing.join(', ')}")
      return false
    end

    updated = 0
    objects.each do |object|
      changed = apply_efficiency(object, metric, value)
      if changed
        updated += 1
        runner.registerInfo("Set #{metric}=#{value} on '#{object.name.get}'.")
      else
        runner.registerWarning("Object '#{object.name.get}' does not support #{metric}; it was unchanged.")
      end
    end
    if updated.zero?
      runner.registerError("None of the named objects support #{metric}.")
      return false
    end

    runner.registerFinalCondition("Updated #{metric} on #{updated} explicitly named objects.")
    true
  end

  private

  def apply_efficiency(object, metric, value)
    case metric
    when 'dx_cooling_cop'
      single = object.to_CoilCoolingDXSingleSpeed
      if single.is_initialized
        single.get.setRatedCOP(value)
        return true
      end
      two_speed = object.to_CoilCoolingDXTwoSpeed
      if two_speed.is_initialized
        two_speed.get.setRatedHighSpeedCOP(value)
        two_speed.get.setRatedLowSpeedCOP(value)
        return true
      end
    when 'dx_heating_cop'
      coil = object.to_CoilHeatingDXSingleSpeed
      return false unless coil.is_initialized

      coil.get.setRatedCOP(value)
      return true
    when 'gas_burner_efficiency'
      coil = object.to_CoilHeatingGas
      return false unless coil.is_initialized

      coil.get.setGasBurnerEfficiency(value)
      return true
    when 'electric_heating_efficiency'
      coil = object.to_CoilHeatingElectric
      return false unless coil.is_initialized

      coil.get.setEfficiency(value)
      return true
    when 'water_to_air_cooling_cop'
      coil = object.to_CoilCoolingWaterToAirHeatPumpEquationFit
      return false unless coil.is_initialized

      coil.get.setRatedCoolingCoefficientofPerformance(value)
      return true
    when 'water_to_air_heating_cop'
      coil = object.to_CoilHeatingWaterToAirHeatPumpEquationFit
      return false unless coil.is_initialized

      coil.get.setRatedHeatingCoefficientofPerformance(value)
      return true
    when 'vrf_cooling_cop'
      system = object.to_AirConditionerVariableRefrigerantFlow
      return false unless system.is_initialized

      system.get.setRatedCoolingCOP(value)
      return true
    when 'vrf_heating_cop'
      system = object.to_AirConditionerVariableRefrigerantFlow
      return false unless system.is_initialized

      system.get.setRatedHeatingCOP(value)
      return true
    end
    false
  end
end

ModifyExistingHvacEquipmentEfficiencies.new.registerWithApplication
