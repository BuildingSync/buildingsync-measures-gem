require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_modifier_tests'
require_relative '../measure'

class ModifyExistingAirLoopControlsTest < HvacMeasureTest
  MEASURE_CLASS = ModifyExistingAirLoopControls
  TEST_DIR = __dir__
  SCOPE_ARGUMENT = 'target_air_loop_names'
  ARGUMENT_NAMES = %w[target_air_loop_names set_supply_air_temperatures cooling_supply_air_temperature_c
                      heating_supply_air_temperature_c set_economizer economizer_control_type
                      economizer_high_limit_dry_bulb_temperature_c economizer_high_limit_enthalpy_j_kg].freeze
  include HvacModifierTests

  def valid_arguments
    {SCOPE_ARGUMENT => 'Air Loop One', 'set_supply_air_temperatures' => true,
     'cooling_supply_air_temperature_c' => 12.5, 'heating_supply_air_temperature_c' => 31.0}
  end

  def controller(name)
    named(:getAirLoopHVACs, name).airLoopHVACOutdoorAirSystem.get.getControllerOutdoorAir
  end

  def test_supply_temperatures_only_on_target
    untouched = named(:getAirLoopHVACs, 'Air Loop Two').sizingSystem.to_s
    outdoor_air = controller('Air Loop One').to_s
    run_measure(valid_arguments)
    sizing = named(:getAirLoopHVACs, 'Air Loop One').sizingSystem
    assert_in_delta(12.5, sizing.centralCoolingDesignSupplyAirTemperature, 1e-9)
    assert_in_delta(31.0, sizing.centralHeatingDesignSupplyAirTemperature, 1e-9)
    assert_equal(untouched, named(:getAirLoopHVACs, 'Air Loop Two').sizingSystem.to_s)
    assert_equal(outdoor_air, controller('Air Loop One').to_s)
  end

  %w[NoEconomizer FixedDryBulb DifferentialDryBulb FixedEnthalpy DifferentialEnthalpy ElectronicEnthalpy].each do |type|
    define_method("test_economizer_#{type}") do
      if type == 'ElectronicEnthalpy'
        controller('Air Loop One').setElectronicEnthalpyLimitCurve(OpenStudio::Model::CurveQuadratic.new(@model))
      end
      untouched = controller('Air Loop Two').to_s
      sizing = named(:getAirLoopHVACs, 'Air Loop One').sizingSystem.to_s
      run_measure(SCOPE_ARGUMENT => 'Air Loop One', 'set_economizer' => true, 'economizer_control_type' => type,
                  'economizer_high_limit_dry_bulb_temperature_c' => 22.0, 'economizer_high_limit_enthalpy_j_kg' => 60_000.0)
      target = controller('Air Loop One')
      assert_equal(type, target.getEconomizerControlType)
      assert_in_delta(22.0, target.getEconomizerMaximumLimitDryBulbTemperature.get, 1e-9) if type.include?('DryBulb')
      assert_in_delta(60_000.0, target.getEconomizerMaximumLimitEnthalpy.get, 1e-9) if type.include?('Enthalpy')
      assert_equal(untouched, controller('Air Loop Two').to_s)
      assert_equal(sizing, named(:getAirLoopHVACs, 'Air Loop One').sizingSystem.to_s)
    end
  end

  def test_combined_controls_and_multiple_names
    run_measure(valid_arguments.merge(SCOPE_ARGUMENT => ' Air Loop One, Air Loop Two, Air Loop One, ', 'set_economizer' => true))
    %w[One Two].each do |suffix|
      assert_in_delta(12.5, named(:getAirLoopHVACs, "Air Loop #{suffix}").sizingSystem.centralCoolingDesignSupplyAirTemperature, 1e-9)
      assert_equal('FixedDryBulb', controller("Air Loop #{suffix}").getEconomizerControlType)
    end
  end

  def test_no_selected_changes_is_not_applicable
    before = snapshot
    run_measure({SCOPE_ARGUMENT => 'Air Loop One'}, expected: 'NA')
    assert_equal(before, snapshot)
  end

  def test_missing_electronic_curve_rejects_before_temperature_update
    values = valid_arguments.merge('set_economizer' => true, 'economizer_control_type' => 'ElectronicEnthalpy')
    assert_rejected_without_changes(values, error: /requires an electronic enthalpy limit curve/)
  end

  def test_warns_when_loop_has_no_outdoor_air_system
    named(:getAirLoopHVACs, 'Air Loop One').airLoopHVACOutdoorAirSystem.get.remove
    before = snapshot
    result = run_measure(SCOPE_ARGUMENT => 'Air Loop One', 'set_economizer' => true)
    assert_match(/no outdoor-air system/, result.warnings.map(&:logMessage).join)
    assert_equal(before, snapshot)
  end
end