require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class ModifyEnvelopeInsulationTest < Minitest::Test
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
    measure = ModifyEnvelopeInsulation.new
    model = load_test_model
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
  end

  def test_good_argument_values
    measure = ModifyEnvelopeInsulation.new
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)
    model = load_test_model
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    args_hash = {}
    args_hash['wall_target_rvalue'] = 0.0
    args_hash['roof_target_rvalue'] = 0.0
    args_hash['floor_target_rvalue'] = 0.0
    args_hash['wall_target_uvalue'] = 0.0
    args_hash['roof_target_uvalue'] = 0.0
    args_hash['floor_target_uvalue'] = 0.0
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
    assert_includes(['Success', 'NA'], result.value.valueName)
  end
end
