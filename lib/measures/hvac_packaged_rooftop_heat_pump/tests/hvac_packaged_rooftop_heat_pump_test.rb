require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacPackagedRooftopHeatPumpTest < HvacMeasureTest
  MEASURE_CLASS = HvacPackagedRooftopHeatPump
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    assert_air_service(model, zone_names, loop_count: zone_names.size)
    assert_equal(zone_names.size, model.getCoilHeatingDXSingleSpeeds.size)
    assert_equal(zone_names.size, model.getCoilCoolingDXSingleSpeeds.size)
    assert_no_new_plants(model)
  end

  def test_supplemental_heating_fuel
    arguments = @measure.arguments(@model)
    assert_equal('supplemental_heating_fuel', arguments[3].name)
    assert_equal(%w[Electricity NaturalGas], arguments[3].choiceValues.to_a)
    assert_equal('Electricity', arguments[3].defaultValueAsString)
    run_measure('supplemental_heating_fuel' => 'NaturalGas')
    assert_system(@model, ZONE_NAMES)
    assert_equal(ZONE_NAMES.size, @model.getCoilHeatingGass.size)
    assert_empty(@model.getCoilHeatingElectrics)
  end
end