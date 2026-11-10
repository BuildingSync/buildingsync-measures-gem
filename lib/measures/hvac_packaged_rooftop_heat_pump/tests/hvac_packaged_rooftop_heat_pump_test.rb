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
end