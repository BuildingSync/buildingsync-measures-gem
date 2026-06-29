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
    assert_equal(8, arguments.size)
  end

  def test_good_argument_values
    measure = ModifySchedules.new
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)
    model = load_test_model
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    args_hash = {}
    args_hash['replace_existing'] = true
    args_hash['default_schedule_set_name'] = 'Modified Schedule Set'
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
    result.showOutput
    assert_equal('Success', result.value.valueName)
  end
end
