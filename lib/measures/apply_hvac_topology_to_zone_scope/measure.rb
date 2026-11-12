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
  ZONE_SCOPES = %w[all_model_zones].freeze

  def name = 'Apply HVAC Topology To Zone Scope'
  def description = 'Runs one split HVAC topology measure on thermal-zone names resolved from the model at run time.'
  def modeler_description = 'zone_scope all_model_zones passes every thermal zone in the model, by exact name, to the ' \
                            'selected topology measure. Create and replace keep the topology measure\'s own safety checks.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    args << choice('topology_measure', 'Topology Measure', TOPOLOGY_MEASURES, nil)
    args << choice('operation', 'Operation', %w[create replace], 'create')
    args << choice('zone_scope', 'Zone Scope', ZONE_SCOPES, 'all_model_zones')
    args << choice('standards_template', 'Standards Template', %w[90.1-2013 90.1-2016 90.1-2019], '90.1-2019')
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    topology = runner.getStringArgumentValue('topology_measure', user_arguments)
    zone_names = model.getThermalZones.map(&:nameString).sort
    if zone_names.empty?
      runner.registerError('The model has no thermal zones to bind.')
      return false
    end

    runner.registerInfo("Resolved zone_scope all_model_zones to #{zone_names.size} zones: #{zone_names.join(', ')}.")
    measure = load_topology_measure(topology)
    values = {
      'operation' => runner.getStringArgumentValue('operation', user_arguments),
      'target_zone_names' => zone_names.join(','),
      'standards_template' => runner.getStringArgumentValue('standards_template', user_arguments)
    }
    measure.run(model, runner, argument_map(measure, model, values))
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

  def load_topology_measure(topology)
    measure_dir = File.expand_path(File.join(__dir__, '..', topology))
    class_name = REXML::Document.new(File.read(File.join(measure_dir, 'measure.xml'))).elements['measure/class_name'].text
    require File.join(measure_dir, 'measure.rb')
    Object.const_get(class_name).new
  end

  def argument_map(measure, model, values)
    map = OpenStudio::Measure.convertOSArgumentVectorToMap(measure.arguments(model))
    values.each do |key, value|
      argument = map[key].clone
      raise ArgumentError, "Cannot set #{key}=#{value}" unless argument.setValue(value)

      map[key] = argument
    end
    map
  end
end

ApplyHvacTopologyToZoneScope.new.registerWithApplication
