require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacPackagedRooftopAcTest < HvacMeasureTest
  MEASURE_CLASS = HvacPackagedRooftopAc
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    assert_air_service(model, zone_names, loop_count: zone_names.size)
    assert_equal(zone_names.size, model.getCoilHeatingGass.size)
    assert_equal(zone_names.size, model.getCoilCoolingDXSingleSpeeds.size)
    assert_empty(model.getCoilHeatingWaters)
    assert_no_new_plants(model)
  end
end