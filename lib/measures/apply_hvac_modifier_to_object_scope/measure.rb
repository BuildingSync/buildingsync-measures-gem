require 'json'
require 'rexml/document'

# Resolves an object scope against the model at run time and runs one modify_existing_*
# measure on the resulting exact object names. OSW step arguments are fixed when the
# workflow is written, so a consumer that does not know model object names (for example,
# BuildingSync premises linked to the whole building) uses this measure instead of
# passing names to the modifier directly.
class ApplyHvacModifierToObjectScope < OpenStudio::Measure::ModelMeasure
  # Modifier directory => name of its comma-separated target-names argument.
  MODIFIER_TARGETS = {
    'modify_existing_air_loop_controls' => 'target_air_loop_names',
    'modify_existing_heat_recovery' => 'target_heat_exchanger_names',
    'modify_existing_hvac_equipment_efficiencies' => 'target_object_names',
    'modify_existing_plant_equipment' => 'target_plant_equipment_names',
    'modify_existing_plant_loop_temperatures' => 'target_plant_loop_names'
  }.freeze
  OBJECT_SCOPES = %w[all_matching_objects explicit_object_names].freeze
  PLANT_LOOP_TYPES = %w[any Heating Cooling Condenser].freeze

  # Model getters holding the objects each efficiency metric can change.
  EFFICIENCY_GETTERS = {
    'dx_cooling_cop' => %i[getCoilCoolingDXSingleSpeeds getCoilCoolingDXTwoSpeeds],
    'dx_heating_cop' => %i[getCoilHeatingDXSingleSpeeds],
    'gas_burner_efficiency' => %i[getCoilHeatingGass],
    'electric_heating_efficiency' => %i[getCoilHeatingElectrics],
    'water_to_air_cooling_cop' => %i[getCoilCoolingWaterToAirHeatPumpEquationFits],
    'water_to_air_heating_cop' => %i[getCoilHeatingWaterToAirHeatPumpEquationFits],
    'vrf_cooling_cop' => %i[getAirConditionerVariableRefrigerantFlows],
    'vrf_heating_cop' => %i[getAirConditionerVariableRefrigerantFlows]
  }.freeze

  def name = 'Apply HVAC Modifier To Object Scope'
  def description = 'Runs one modify_existing_* HVAC measure on object names resolved from the model at run time.'
  def modeler_description = 'object_scope all_matching_objects passes every model object the selected modifier and setting ' \
                            'can change, by exact name; explicit_object_names passes the exact names in object_names_json. ' \
                            'The modifier keeps its own checks.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    args << choice('modifier_measure', 'Modifier Measure', MODIFIER_TARGETS.keys, nil)
    args << choice('object_scope', 'Object Scope', OBJECT_SCOPES, 'all_matching_objects')
    args << string('object_names_json', 'Object Names (JSON)', false,
                   'JSON array of exact OpenStudio object names. Used only when object_scope is explicit_object_names.', '')
    args << choice('plant_loop_type', 'Plant Loop Type', PLANT_LOOP_TYPES, 'any',
                   'Sizing:Plant loop type for modify_existing_plant_loop_temperatures with all_matching_objects; required there.')
    args << string('modifier_arguments_json', 'Modifier Arguments (JSON)', true,
                   'JSON object of the modifier\'s other arguments, e.g. {"efficiency_metric":"dx_cooling_cop","efficiency_value":4.0}.',
                   '{}')
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    modifier = runner.getStringArgumentValue('modifier_measure', user_arguments)
    scope = runner.getStringArgumentValue('object_scope', user_arguments)
    target_key = MODIFIER_TARGETS[modifier]
    values = parse_object(runner.getStringArgumentValue('modifier_arguments_json', user_arguments))
    if values.nil?
      runner.registerError('modifier_arguments_json must be a JSON object.')
      return false
    end
    if values.key?(target_key)
      runner.registerError("modifier_arguments_json must not set #{target_key}; it is resolved from object_scope.")
      return false
    end

    if scope == 'explicit_object_names'
      names = parse_names(runner.getStringArgumentValue('object_names_json', user_arguments))
      unless names
        runner.registerError('object_scope explicit_object_names requires object_names_json to be a non-empty JSON array of non-empty strings.')
        return false
      end
    else
      names = matching_names(model, modifier, values, runner.getStringArgumentValue('plant_loop_type', user_arguments))
      if names.is_a?(String)
        runner.registerError(names)
        return false
      end
      if names.empty?
        runner.registerError("The model has no objects #{modifier} can change for the given arguments.")
        return false
      end
    end

    # The modifiers split target names on commas.
    with_commas = names.select { |object_name| object_name.include?(',') }
    unless with_commas.empty?
      runner.registerError("#{modifier} cannot target object names containing commas: #{with_commas.join('; ')}")
      return false
    end

    runner.registerInfo("Resolved object_scope #{scope} to #{names.size} objects: #{names.join(', ')}.")
    measure_dir = File.expand_path(File.join(__dir__, '..', modifier))
    unless File.file?(File.join(measure_dir, 'measure.rb')) && File.file?(File.join(measure_dir, 'measure.xml'))
      runner.registerError("Modifier measure '#{modifier}' was not found at #{measure_dir}. This measure requires the " \
                           'buildingsync-measures modify_existing_* measures installed in the same measures directory.')
      return false
    end

    begin
      measure = load_measure(measure_dir)
      arguments = argument_map(measure, model, values.merge(target_key => names.join(',')))
    rescue StandardError, LoadError => e
      runner.registerError("Could not prepare modifier measure '#{modifier}': #{e.message}")
      return false
    end
    measure.run(model, runner, arguments)
  end

  private

  def choice(name, display_name, values, default, description = nil)
    choices = OpenStudio::StringVector.new
    values.each { |value| choices << value }
    argument = OpenStudio::Measure::OSArgument.makeChoiceArgument(name, choices, true)
    argument.setDisplayName(display_name)
    argument.setDescription(description) if description
    argument.setDefaultValue(default) if default
    argument
  end

  def string(name, display_name, required, description, default)
    argument = OpenStudio::Measure::OSArgument.makeStringArgument(name, required)
    argument.setDisplayName(display_name)
    argument.setDescription(description)
    argument.setDefaultValue(default)
    argument
  end

  def parse_object(text)
    value = JSON.parse(text)
    value.is_a?(Hash) ? value : nil
  rescue JSON::ParserError
    nil
  end

  # Returns the unique names, or nil when the text is not a non-empty JSON array of non-empty strings.
  def parse_names(text)
    names = JSON.parse(text)
    return nil unless names.is_a?(Array) && !names.empty? && names.all? { |name| name.is_a?(String) && !name.strip.empty? }

    names.uniq
  rescue JSON::ParserError
    nil
  end

  # Sorted names of every object the modifier can change with these arguments, or an error message.
  def matching_names(model, modifier, values, plant_loop_type)
    objects =
      case modifier
      when 'modify_existing_air_loop_controls' then model.getAirLoopHVACs
      when 'modify_existing_heat_recovery' then model.getHeatExchangerAirToAirSensibleAndLatents
      when 'modify_existing_hvac_equipment_efficiencies'
        getters = EFFICIENCY_GETTERS[values['efficiency_metric']]
        return 'all_matching_objects requires a supported efficiency_metric in modifier_arguments_json.' if getters.nil?

        getters.flat_map { |getter| model.public_send(getter).to_a }
      when 'modify_existing_plant_equipment'
        property = values['property'].to_s
        if property.start_with?('boiler_') then model.getBoilerHotWaters
        elsif property.start_with?('chiller_') then model.getChillerElectricEIRs
        else
          return 'all_matching_objects requires a supported property in modifier_arguments_json.'
        end
      when 'modify_existing_plant_loop_temperatures'
        return 'all_matching_objects requires plant_loop_type Heating, Cooling, or Condenser.' if plant_loop_type == 'any'

        model.getPlantLoops.select { |plant_loop| plant_loop.sizingPlant.loopType == plant_loop_type }
      end
    objects.map(&:nameString).uniq.sort
  end

  def load_measure(measure_dir)
    class_name = REXML::Document.new(File.read(File.join(measure_dir, 'measure.xml'))).elements['measure/class_name'].text
    require File.join(measure_dir, 'measure.rb')
    Object.const_get(class_name).new
  end

  def argument_map(measure, model, values)
    known = measure.arguments(model).map(&:name)
    map = OpenStudio::Measure.convertOSArgumentVectorToMap(measure.arguments(model))
    values.each do |key, value|
      raise ArgumentError, "Unknown argument #{key}" unless known.include?(key)

      argument = map[key].clone
      raise ArgumentError, "Cannot set #{key}=#{value.inspect}" unless argument.setValue(typed(argument, value))

      map[key] = argument
    end
    map
  end

  def typed(argument, value)
    case argument.type.valueName
    when 'Double' then Float(value)
    when 'Integer' then Integer(value)
    when 'Boolean'
      raise ArgumentError, "#{argument.name} must be true or false" unless [true, false].include?(value)

      value
    else value.to_s
    end
  end
end

ApplyHvacModifierToObjectScope.new.registerWithApplication
