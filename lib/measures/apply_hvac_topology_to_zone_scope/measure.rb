require 'json'
require 'rexml/document'

# Resolves a zone scope against the model at run time and runs one split HVAC topology
# measure on the resulting exact zone names. OSW step arguments are fixed when the
# workflow is written, so a consumer that does not know model zone names (for example,
# BuildingSync premises linked to the whole building) uses this measure instead of
# passing names to the topology measure directly.
class ApplyHvacTopologyToZoneScope < OpenStudio::Measure::ModelMeasure
  TOPOLOGY_MEASURES = %w[
    hvac_chilled_beam hvac_doas hvac_four_pipe_fan_coil hvac_ground_source_heat_pump
    hvac_packaged_rooftop_ac hvac_packaged_rooftop_heat_pump hvac_packaged_rooftop_vav_electric_reheat
    hvac_packaged_rooftop_vav_hw_reheat hvac_ptac hvac_pthp hvac_radiant hvac_vav_electric_reheat
    hvac_vav_hw_reheat hvac_ventilation_only hvac_vrf hvac_warm_air_furnace hvac_water_loop_heat_pump
  ].freeze
  ZONE_SCOPES = %w[all_model_zones explicit_zone_names].freeze
  # Set by this measure; topology_arguments_json must not override them.
  RESERVED_ARGUMENTS = %w[operation target_zone_names standards_template].freeze

  def name = 'Apply HVAC Topology To Zone Scope'
  def description = 'Runs one split HVAC topology measure on thermal-zone names resolved from the model at run time.'
  def modeler_description = 'zone_scope all_model_zones passes every thermal zone in the model, by exact name, to the ' \
                            'selected topology measure; explicit_zone_names passes the exact names listed in zone_names_json. ' \
                            'Create and replace keep the topology measure\'s own safety checks.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    args << choice('topology_measure', 'Topology Measure', TOPOLOGY_MEASURES, nil)
    args << choice('operation', 'Operation', %w[create replace], 'create')
    args << choice('zone_scope', 'Zone Scope', ZONE_SCOPES, 'all_model_zones')
    names = OpenStudio::Measure::OSArgument.makeStringArgument('zone_names_json', false)
    names.setDisplayName('Zone Names (JSON)')
    names.setDescription('JSON array of exact thermal-zone names, e.g. ["Zone A","Office, East"]. Used only when zone_scope is explicit_zone_names.')
    names.setDefaultValue('')
    args << names
    args << choice('standards_template', 'Standards Template',
                   ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010',
                    '90.1-2013', '90.1-2016', '90.1-2019'], '90.1-2019')
    extra = OpenStudio::Measure::OSArgument.makeStringArgument('topology_arguments_json', false)
    extra.setDisplayName('Topology Arguments (JSON)')
    extra.setDescription('JSON object of other topology-measure arguments, e.g. {"supplemental_heating_fuel":"NaturalGas"}. ' \
                         'Must not set operation, target_zone_names, or standards_template.')
    extra.setDefaultValue('')
    args << extra
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    topology = runner.getStringArgumentValue('topology_measure', user_arguments)
    scope = runner.getStringArgumentValue('zone_scope', user_arguments)
    extra = parse_topology_arguments(runner.getStringArgumentValue('topology_arguments_json', user_arguments))
    unless extra
      runner.registerError('topology_arguments_json must be empty or a JSON object of string values that does not set ' \
                           "#{RESERVED_ARGUMENTS.join(', ')}.")
      return false
    end
    model_names = model.getThermalZones.map(&:nameString).sort
    if model_names.empty?
      runner.registerError('The model has no thermal zones to bind.')
      return false
    end

    if scope == 'explicit_zone_names'
      zone_names = parse_zone_names(runner.getStringArgumentValue('zone_names_json', user_arguments))
      unless zone_names
        runner.registerError('zone_scope explicit_zone_names requires zone_names_json to be a non-empty JSON array of non-empty strings.')
        return false
      end
      missing = zone_names - model_names
      unless missing.empty?
        runner.registerError("Thermal zones not found: #{missing.join(', ')}")
        return false
      end
    else
      zone_names = model_names
    end

    runner.registerInfo("Resolved zone_scope #{scope} to #{zone_names.size} zones: #{zone_names.join(', ')}.")
    measure_dir = File.expand_path(File.join(__dir__, '..', topology))
    unless File.file?(File.join(measure_dir, 'measure.rb')) && File.file?(File.join(measure_dir, 'measure.xml'))
      runner.registerError("Topology measure '#{topology}' was not found at #{measure_dir}. This measure requires the " \
                           'buildingsync-measures hvac_* measures installed in the same measures directory.')
      return false
    end

    begin
      measure = load_topology_measure(measure_dir)
      values = {
        'operation' => runner.getStringArgumentValue('operation', user_arguments),
        # JSON keeps exact names, including names containing commas.
        'target_zone_names' => JSON.generate(zone_names),
        'standards_template' => runner.getStringArgumentValue('standards_template', user_arguments)
      }.merge(extra)
      arguments = argument_map(measure, model, values)
    rescue StandardError, LoadError => e
      runner.registerError("Could not prepare topology measure '#{topology}': #{e.message}")
      return false
    end
    measure.run(model, runner, arguments)
  end

  private

  def choice(name, display_name, values, default)
    choices = OpenStudio::StringVector.new
    values.each { |value| choices << value }
    argument = OpenStudio::Measure::OSArgument.makeChoiceArgument(name, choices, true)
    argument.setDisplayName(display_name)
    argument.setDefaultValue(default) if default
    argument
  end

  # Returns the unique names, or nil when the text is not a non-empty JSON array of non-empty strings.
  def parse_zone_names(text)
    names = JSON.parse(text)
    return nil unless names.is_a?(Array) && !names.empty? && names.all? { |name| name.is_a?(String) && !name.strip.empty? }

    names.uniq
  rescue JSON::ParserError
    nil
  end

  # Returns a Hash, or nil when the text is not empty or a JSON object of string values without reserved keys.
  def parse_topology_arguments(text)
    return {} if text.strip.empty?

    values = JSON.parse(text)
    return nil unless values.is_a?(Hash) && values.values.all?(String) && (values.keys & RESERVED_ARGUMENTS).empty?

    values
  rescue JSON::ParserError
    nil
  end

  def load_topology_measure(measure_dir)
    class_name = REXML::Document.new(File.read(File.join(measure_dir, 'measure.xml'))).elements['measure/class_name'].text
    require File.join(measure_dir, 'measure.rb')
    Object.const_get(class_name).new
  end

  def argument_map(measure, model, values)
    map = OpenStudio::Measure.convertOSArgumentVectorToMap(measure.arguments(model))
    values.each do |key, value|
      raise ArgumentError, "Unknown argument #{key}" if map[key].nil?

      argument = map[key].clone
      raise ArgumentError, "Cannot set #{key}=#{value}" unless argument.setValue(value)

      map[key] = argument
    end
    map
  end
end

ApplyHvacTopologyToZoneScope.new.registerWithApplication
