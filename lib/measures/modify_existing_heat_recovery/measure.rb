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
    names.setDescription('Comma-separated exact HeatExchangerAirToAirSensibleAndLatent names, or a JSON array of exact names (for names containing commas).')
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

    require 'json'
    text = runner.getStringArgumentValue('target_heat_exchanger_names', user_arguments).strip
    begin
      names = text.start_with?('[') ? JSON.parse(text) : text.split(',')
    rescue JSON::ParserError
      names = nil
    end
    unless names.is_a?(Array) && names.all? { |value| value.is_a?(String) }
      runner.registerError('target_heat_exchanger_names must be comma-separated names or a JSON array of strings.')
      return false
    end
    names = names.map(&:strip).reject(&:empty?).uniq
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

    prefix = metric == 'sensible_effectiveness' ? 'Sensible' : 'Latent'
    # The 75% airflow setters only succeed when no curve or a TableLookup curve is attached.
    unsupported = exchangers.select do |heat_exchanger|
      %w[Cooling Heating].any? do |mode|
        curve = heat_exchanger.send("#{prefix.downcase}Effectivenessof#{mode}AirFlowCurve")
        curve.is_initialized && curve.get.to_TableLookup.empty?
      end
    end
    unless unsupported.empty?
      runner.registerError("Cannot set #{metric} on heat exchangers with non-TableLookup effectiveness curves: " \
                           "#{unsupported.map { |item| item.name.to_s }.join(', ')}")
      return false
    end

    exchangers.each do |heat_exchanger|
      # Since SDK 3.8 the 75% setters normalize a curve by the 100% value, and a
      # zero reference raises a division-by-zero exception. Always build a neutral
      # (ratio 1.0) curve at a reference of 1.0, then set only the 100% fields so
      # the 75% values follow regardless of the exchanger's previous state.
      failed = %w[100Cooling 75Cooling 100Heating 75Heating].reject do |suffix|
        heat_exchanger.send("set#{prefix}Effectivenessat#{suffix}AirFlow", 1.0)
      end
      if failed.empty?
        failed += %w[100Cooling 100Heating].reject do |suffix|
          heat_exchanger.send("set#{prefix}Effectivenessat#{suffix}AirFlow", value)
        end
      end
      unless failed.empty?
        runner.registerError("Failed to set #{metric} at #{failed.join(', ')} airflow on '#{heat_exchanger.name}'.")
        return false
      end
      runner.registerInfo("Set #{metric}=#{value} on '#{heat_exchanger.name}'.")
    end

    runner.registerFinalCondition("Updated #{metric} on #{exchangers.size} heat exchangers.")
    true
  end
end

ModifyExistingHeatRecovery.new.registerWithApplication
