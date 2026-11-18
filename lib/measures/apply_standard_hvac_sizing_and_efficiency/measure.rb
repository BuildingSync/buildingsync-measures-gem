# Runs the HVAC sizing and efficiency tail that openstudio-standards create_typical_building_from_model
# skips when add_hvac is false. Use it after split topology measures have created the HVAC, so a
# typical-building workflow still gets sized, standards-efficient equipment.
class ApplyStandardHvacSizingAndEfficiency < OpenStudio::Measure::ModelMeasure
  def name = 'Apply Standard HVAC Sizing And Efficiency'
  def description = 'Sizes existing HVAC with a sizing run and applies prototype assumptions and 90.1 efficiencies.'
  def modeler_description = 'Mirrors the add_hvac tail of OpenstudioStandards::CreateTypical.create_typical_building_from_model ' \
                            '(openstudio-standards 0.8.x): PRM sizing parameters, sizing run, multizone VAV outdoor-air ' \
                            'sizing, prototype HVAC assumptions, HVAC efficiency standard, NIST infiltration schedules, ' \
                            'and thermostat night-cycle control. Requires the building standards type and climate zone ' \
                            'that create_typical_building_from_model sets.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    choices = OpenStudio::StringVector.new
    ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010', '90.1-2013', '90.1-2016', '90.1-2019']
      .each { |value| choices << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', choices, true)
    template.setDisplayName('Standards Template')
    template.setDefaultValue('90.1-2019')
    args << template
    infiltration = OpenStudio::Measure::OSArgument.makeBoolArgument('add_infiltration_schedules', true)
    infiltration.setDisplayName('Apply NIST Infiltration Schedules')
    infiltration.setDefaultValue(true)
    args << infiltration
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    if model.getAirLoopHVACs.empty? && model.getThermalZones.all? { |zone| zone.equipment.empty? }
      runner.registerError('The model has no HVAC to size.')
      return false
    end
    building_type = model.getBuilding.standardsBuildingType
    unless building_type.is_initialized
      runner.registerError('The building has no standards building type; run create_typical_building_from_model first.')
      return false
    end

    require 'openstudio-standards'
    template = runner.getStringArgumentValue('standards_template', user_arguments)
    standard = Standard.build(template)
    climate_zone = standard.model_get_building_properties(model)['climate_zone']
    if climate_zone.to_s.empty?
      runner.registerError('The model has no ASHRAE climate zone.')
      return false
    end

    sized = with_standards_log(runner, 'sizing run') do
      standard.model_apply_prm_sizing_parameters(model)
      standard.model_run_sizing_run(model, File.join(Dir.pwd, 'apply_standard_hvac_sizing_SR'))
    end
    unless sized
      runner.registerError('The sizing run failed.')
      return false
    end
    applied = with_standards_log(runner, 'efficiency') do
      standard.model_apply_multizone_vav_outdoor_air_sizing(model)
      standard.model_apply_prototype_hvac_assumptions(model, building_type.get, climate_zone)
      standard.model_apply_hvac_efficiency_standard(model, climate_zone)
      if runner.getBoolArgumentValue('add_infiltration_schedules', user_arguments)
        OpenstudioStandards::Infiltration.model_set_nist_infiltration_schedules(model)
      end
      true
    end
    unless applied
      runner.registerError('openstudio-standards reported errors while applying HVAC assumptions and efficiencies.')
      return false
    end
    model.getAvailabilityManagerNightCycles.each do |night_cycle|
      night_cycle.setThermostatTolerance(1.9999)
      night_cycle.setCyclingRunTimeControlType('Thermostat')
    end

    runner.registerFinalCondition("Sized HVAC and applied #{template} efficiencies for #{building_type.get} in #{climate_zone}.")
    true
  rescue StandardError => e
    runner.registerError("HVAC sizing and efficiency failed: #{e.message}")
    false
  end

  # Log messages that openstudio-standards itself treats as noise when forwarding its log to a runner.
  STANDARDS_LOG_NOISE = ['UseWeatherFile', 'Skipping layer', 'has multiple parents', 'Successive data points',
                         'does not have an Output', 'Prior to OpenStudio 2.6.2'].freeze

  private

  # openstudio-standards logs skipped equipment (for example, a failed efficiency lookup) without raising.
  # Capture the log while the block runs, forward warnings to the runner, and report errors, in which case
  # the step counts as failed.
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

ApplyStandardHvacSizingAndEfficiency.new.registerWithApplication
