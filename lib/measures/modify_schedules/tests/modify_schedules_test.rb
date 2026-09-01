require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class ModifySchedulesTest < Minitest::Test
  def load_test_model
    test_model = File.join(File.dirname(__FILE__), 'test_model.osm')
    if File.exist?(test_model)
      vt = OpenStudio::OSVersion::VersionTranslator.new
      model = vt.loadModel(OpenStudio::Path.new(test_model))
      return model.get if model.is_initialized
    end
    OpenStudio::Model::Model.new
  end

  def test_number_of_arguments
    measure = ModifySchedules.new
    model = load_test_model
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
  end

  def argument_map_for(measure, model, overrides = {})
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    arguments.each do |argument|
      argument_value = argument.clone
      assert(argument_value.setValue(overrides[argument.name])) if overrides.key?(argument.name)
      argument_map[argument.name] = argument_value
    end
    argument_map
  end

  def test_default_arguments_make_no_changes
    measure = ModifySchedules.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = load_test_model
    schedule_count = model.getSchedules.size
    space_type_schedule_sets = model.getSpaceTypes.map do |space_type|
      space_type.defaultScheduleSet.is_initialized ? space_type.defaultScheduleSet.get.handle.to_s : nil
    end

    measure.run(model, runner, argument_map_for(measure, model))

    assert_equal('NA', runner.result.value.valueName)
    assert_equal(schedule_count, model.getSchedules.size)
    assert_equal(space_type_schedule_sets, model.getSpaceTypes.map { |space_type| space_type.defaultScheduleSet.is_initialized ? space_type.defaultScheduleSet.get.handle.to_s : nil })
  end

  def test_lighting_only_does_not_reset_occupancy
    measure = ModifySchedules.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    space_type = OpenStudio::Model::SpaceType.new(model)

    occupancy_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    occupancy_schedule.setName('Existing Occupancy Schedule')
    people_definition = OpenStudio::Model::PeopleDefinition.new(model)
    people = OpenStudio::Model::People.new(people_definition)
    people.setSpaceType(space_type)
    people.setNumberofPeopleSchedule(occupancy_schedule)

    old_lighting_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    old_lighting_schedule.setName('BuildingSync Lighting')
    lights_definition = OpenStudio::Model::LightsDefinition.new(model)
    lights = OpenStudio::Model::Lights.new(lights_definition)
    lights.setSpaceType(space_type)
    lights.setSchedule(old_lighting_schedule)

    lighting_payload = 'name=BuildingSync Lighting;schedule_category=Lighting;Weekday|00:00:00|24:00:00|50'
    arguments = argument_map_for(measure, model, { 'lighting_schedule_json' => lighting_payload })

    measure.run(model, runner, arguments)

    assert_equal('Success', runner.result.value.valueName)
    assert(people.numberofPeopleSchedule.is_initialized)
    assert_equal(occupancy_schedule.handle, people.numberofPeopleSchedule.get.handle)
    refute(model.getBuilding.defaultScheduleSet.is_initialized)
    generated_lighting_schedule = lights.schedule.get
    assert_equal('BuildingSync Lighting', old_lighting_schedule.name.to_s)
    refute_equal(old_lighting_schedule.handle, generated_lighting_schedule.handle)
    assert_equal('BuildingSync Lighting_modified', generated_lighting_schedule.name.to_s)
    assert_equal(generated_lighting_schedule.handle, lights.schedule.get.handle)
  end

  def test_modified_schedule_name_uses_numeric_suffix_when_taken
    measure = ModifySchedules.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    existing_modified_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    existing_modified_schedule.setName('BuildingSync Lighting_modified')
    lighting_payload = 'name=BuildingSync Lighting;schedule_category=Lighting;Weekday|00:00:00|24:00:00|50'

    arguments = argument_map_for(measure, model, { 'lighting_schedule_json' => lighting_payload })
    measure.run(model, runner, arguments)

    assert_equal('Success', runner.result.value.valueName)
    generated_schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == 'BuildingSync Lighting_modified_2' }
    refute_nil(generated_schedule)
    assert_equal('BuildingSync Lighting_modified_2', generated_schedule.name.to_s)
    assert_equal('BuildingSync Lighting_modified', existing_modified_schedule.name.to_s)
    refute_equal(existing_modified_schedule.handle, generated_schedule.handle)
  end

  def test_good_argument_values
    measure = ModifySchedules.new
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)
    model = load_test_model
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    args_hash = {}
    args_hash['occupancy_schedule_json'] = 'name=Modified Occupancy Schedule;schedule_category=Occupied;Weekday|00:00:00|06:00:00|0;Weekday|06:00:00|07:00:00|11;Weekday|07:00:00|08:00:00|21;Weekday|08:00:00|12:00:00|100;Weekday|12:00:00|13:00:00|53;Weekday|13:00:00|17:00:00|100;Weekday|17:00:00|18:00:00|32;Weekday|18:00:00|22:00:00|11;Weekday|22:00:00|23:00:00|5;Weekday|23:00:00|23:59:59|0;Weekend|00:00:00|23:59:59|0;Holiday|00:00:00|23:59:59|0'
    args_hash['lighting_schedule_json'] = 'name=Modified Lighting Schedule;schedule_category=Lighting;Weekday|00:00:00|05:00:00|18;Weekday|05:00:00|07:00:00|23;Weekday|07:00:00|08:00:00|42;Weekday|08:00:00|12:00:00|90;Weekday|12:00:00|13:00:00|80;Weekday|13:00:00|17:00:00|90;Weekday|17:00:00|18:00:00|61;Weekday|18:00:00|20:00:00|42;Weekday|20:00:00|22:00:00|32;Weekday|22:00:00|23:00:00|23;Weekday|23:00:00|23:59:59|18;Weekend|00:00:00|23:59:59|18;Holiday|00:00:00|23:59:59|18'
    args_hash['electric_equipment_schedule_json'] = 'name=Modified Plug Load Schedule;schedule_category=Miscellaneous equipment;Weekday|00:00:00|08:00:00|50;Weekday|08:00:00|12:00:00|100;Weekday|12:00:00|13:00:00|94;Weekday|13:00:00|17:00:00|100;Weekday|17:00:00|18:00:00|50;Weekday|18:00:00|23:59:59|20;Weekend|00:00:00|23:59:59|20;Holiday|00:00:00|23:59:59|20'
    args_hash['gas_equipment_schedule_json'] = 'name=Modified Gas Equipment Schedule;schedule_category=Gas equipment;Weekday|00:00:00|08:00:00|20;Weekday|08:00:00|18:00:00|100;Weekday|18:00:00|23:59:59|30;Weekend|00:00:00|23:59:59|10;Holiday|00:00:00|23:59:59|10'
    args_hash['hvac_availability_schedule_json'] = 'name=Modified HVAC Availability Schedule;schedule_category=HVAC equipment;Weekday|00:00:00|06:00:00|0;Weekday|06:00:00|07:00:00|60;Weekday|07:00:00|12:00:00|100;Weekday|12:00:00|13:00:00|80;Weekday|13:00:00|18:00:00|100;Weekday|18:00:00|20:00:00|60;Weekday|20:00:00|23:59:59|0;Weekend|00:00:00|23:59:59|0;Holiday|00:00:00|23:59:59|0'
    args_hash['additional_schedules_json'] = '[]'
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)
  end
end
