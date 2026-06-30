require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class ModifyHvacTest < Minitest::Test
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
    measure = ModifyHvac.new
    model = load_test_model
    arguments = measure.arguments(model)
    assert_equal(31, arguments.size)
  end

  def test_good_argument_values
    measure = ModifyHvac.new
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)
    model = load_test_model
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    args_hash = {}
    args_hash['hvac_system_type'] = 'vav_with_hot_water_reheat'
    args_hash['target_air_loop_name'] = ''
    args_hash['target_zone_names'] = ''
    args_hash['synthesize_if_missing'] = true
    args_hash['economizer_control_type'] = 'FixedDryBulb'
    args_hash['economizer_high_limit_dry_bulb_temperature_c'] = 24.0
    args_hash['economizer_high_limit_enthalpy_j_kg'] = 64000.0
    args_hash['central_cooling_supply_air_temperature_c'] = 12.8
    args_hash['central_heating_supply_air_temperature_c'] = 32.0
    args_hash['doas_supply_air_temperature_c'] = 18.3
    args_hash['erv_sensible_effectiveness'] = 0.0
    args_hash['erv_latent_effectiveness'] = 0.0
    args_hash['design_heating_capacity_kw'] = 0.0
    args_hash['design_cooling_capacity_tons'] = 0.0
    args_hash['boiler_capacity_kw'] = 0.0
    args_hash['boiler_nominal_thermal_efficiency'] = 0.85
    args_hash['chiller_capacity_tons'] = 0.0
    args_hash['chiller_reference_cop'] = 5.5
    args_hash['dx_cooling_cop'] = 3.5
    args_hash['gas_furnace_thermal_efficiency'] = 0.8
    args_hash['heat_pump_cooling_cop'] = 3.5
    args_hash['heat_pump_heating_cop'] = 3.2
    args_hash['backup_resistance_efficiency'] = 1.0
    args_hash['radiant_chilled_water_supply_temperature_c'] = 15.6
    args_hash['radiant_hot_water_supply_temperature_c'] = 43.3
    args_hash['chilled_beam_primary_air_fraction'] = 0.3
    args_hash['year_installed'] = 2015
    args_hash['condition_assessment'] = 'average'
    args_hash['control_type_audit'] = 'direct_digital_control'
    args_hash['zone_control_strategy'] = 'core_perimeter'
    args_hash['preserve_existing_sizing'] = false
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
