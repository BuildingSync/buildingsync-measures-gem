require 'json'

class ModifyExistingHeatRecovery < OpenStudio::Measure::ModelMeasure
  ALL_TARGETS = '*'
  # ComStock upgrade_hvac_exhaust_air_energy_or_heat_recovery ERV values, already derated by 0.90.
  COMSTOCK_ERV = {
    'Sensible' => { '100Heating' => 0.75 * 0.9, '75Heating' => 0.78 * 0.9,
                    '100Cooling' => 0.75 * 0.9, '75Cooling' => 0.78 * 0.9 },
    'Latent' => { '100Heating' => 0.61 * 0.9, '75Heating' => 0.68 * 0.9,
                  '100Cooling' => 0.55 * 0.9, '75Cooling' => 0.60 * 0.9 }
  }.freeze

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
    names.setDescription('Comma-separated exact HeatExchangerAirToAirSensibleAndLatent names, a JSON array of exact names ' \
                         "(for names containing commas), or '#{ALL_TARGETS}' for every heat exchanger in the model.")
    args << names

    metrics = OpenStudio::StringVector.new
    %w[sensible_effectiveness latent_effectiveness comstock_erv].each { |metric| metrics << metric }
    metric = OpenStudio::Measure::OSArgument.makeChoiceArgument('effectiveness_metric', metrics, true)
    metric.setDisplayName('Effectiveness Metric')
    metric.setDescription('comstock_erv sets all sensible and latent fields to the ComStock ERV values and ignores Effectiveness.')
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

    text = runner.getStringArgumentValue('target_heat_exchanger_names', user_arguments).strip
    all_targets = text == ALL_TARGETS
    begin
      names = all_targets ? [] : (text.start_with?('[') ? JSON.parse(text) : text.split(','))
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
    if (names.empty? && !all_targets) || !value.between?(0.0, 1.0)
      runner.registerError('At least one exact name and an effectiveness in [0, 1] are required.')
      return false
    end

    exchangers = model.getHeatExchangerAirToAirSensibleAndLatents.select do |item|
      all_targets || names.include?(item.name.to_s)
    end
    if all_targets && exchangers.empty?
      runner.registerError('The model has no heat exchangers.')
      return false
    end
    missing = names - exchangers.map { |item| item.name.to_s }
    unless missing.empty?
      runner.registerError("Heat exchangers not found: #{missing.join(', ')}")
      return false
    end

    prefixes = { 'sensible_effectiveness' => %w[Sensible], 'latent_effectiveness' => %w[Latent],
                 'comstock_erv' => %w[Sensible Latent] }.fetch(metric)
    # The 75% airflow setters only succeed when no curve or a TableLookup curve is attached.
    unsupported = exchangers.select do |heat_exchanger|
      prefixes.product(%w[Cooling Heating]).any? do |prefix, mode|
        curve = heat_exchanger.send("#{prefix.downcase}Effectivenessof#{mode}AirFlowCurve")
        curve.is_initialized && curve.get.to_TableLookup.empty?
      end
    end
    unless unsupported.empty?
      runner.registerError("Cannot set #{metric} on heat exchangers with non-TableLookup effectiveness curves: " \
                           "#{unsupported.map { |item| item.name.to_s }.join(', ')}")
      return false
    end

    if metric == 'comstock_erv'
      exchangers.each do |heat_exchanger|
        # The 75% setters store value / (100% value at curve creation). Pin the 100% value to 1.0,
        # store the 75/100 ratio, then set the 100% value so the 75% value reads as intended.
        failed = prefixes.product(%w[Cooling Heating]).reject do |prefix, mode|
          values = COMSTOCK_ERV[prefix]
          heat_exchanger.send("set#{prefix}Effectivenessat100#{mode}AirFlow", 1.0) &&
            heat_exchanger.send("set#{prefix}Effectivenessat75#{mode}AirFlow", values["75#{mode}"] / values["100#{mode}"]) &&
            heat_exchanger.send("set#{prefix}Effectivenessat100#{mode}AirFlow", values["100#{mode}"])
        end.map { |prefix, mode| "#{prefix} #{mode}" }
        unless failed.empty?
          runner.registerError("Failed to set #{failed.join(', ')} airflow on '#{heat_exchanger.name}'.")
          return false
        end
        runner.registerInfo("Set ComStock ERV effectiveness on '#{heat_exchanger.name}'.")
      end
      runner.registerValue('heat_exchangers_updated', exchangers.size)
      runner.registerFinalCondition("Updated #{metric} on #{exchangers.size} heat exchangers.")
      return true
    end

    prefix = prefixes.first
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
