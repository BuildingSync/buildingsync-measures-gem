class ModifyExistingHeatRecovery < OpenStudio::Measure::ModelMeasure
  def name
    'Modify Existing Heat Recovery'
  end

  def description
    'Sets sensible or latent effectiveness on explicitly named air-to-air heat exchangers.'
  end

  def modeler_description
    'Updates all 100% and 75% heating/cooling effectiveness fields for the selected metric.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_heat_exchanger_names', true)
    names.setDisplayName('Target Heat Exchanger Names')
    names.setDescription('Comma-separated exact HeatExchangerAirToAirSensibleAndLatent names.')
    args << names

    metrics = OpenStudio::StringVector.new
    %w[sensible_effectiveness latent_effectiveness].each { |metric| metrics << metric }
    metric = OpenStudio::Measure::OSArgument.makeChoiceArgument('effectiveness_metric', metrics, true)
    metric.setDisplayName('Effectiveness Metric')
    metric.setDefaultValue('sensible_effectiveness')
    args << metric

    value = OpenStudio::Measure::OSArgument.makeDoubleArgument('effectiveness', true)
    value.setDisplayName('Effectiveness')
    value.setDescription('Fraction from 0 through 1.')
    value.setDefaultValue(0.7)
    args << value

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    names = runner.getStringArgumentValue('target_heat_exchanger_names', user_arguments)
                  .split(',').map(&:strip).reject(&:empty?).uniq
    metric = runner.getStringArgumentValue('effectiveness_metric', user_arguments)
    value = runner.getDoubleArgumentValue('effectiveness', user_arguments)
    if names.empty? || !value.between?(0.0, 1.0)
      runner.registerError('At least one exact name and an effectiveness in [0, 1] are required.')
      return false
    end

    exchangers = model.getHeatExchangerAirToAirSensibleAndLatents.select do |item|
      names.include?(item.name.to_s)
    end
    missing = names - exchangers.map { |item| item.name.to_s }
    unless missing.empty?
      runner.registerError("Heat exchangers not found: #{missing.join(', ')}")
      return false
    end

    exchangers.each do |heat_exchanger|
      if metric == 'sensible_effectiveness'
        heat_exchanger.setSensibleEffectivenessat100CoolingAirFlow(value)
        heat_exchanger.setSensibleEffectivenessat75CoolingAirFlow(value)
        heat_exchanger.setSensibleEffectivenessat100HeatingAirFlow(value)
        heat_exchanger.setSensibleEffectivenessat75HeatingAirFlow(value)
      else
        heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(value)
        heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(value)
        heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(value)
        heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(value)
      end
      runner.registerInfo("Set #{metric}=#{value} on '#{heat_exchanger.name}'.")
    end

    runner.registerFinalCondition("Updated #{metric} on #{exchangers.size} heat exchangers.")
    true
  end
end

ModifyExistingHeatRecovery.new.registerWithApplication
