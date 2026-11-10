require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacWarmAirFurnaceTest < HvacMeasureTest
  MEASURE_CLASS = HvacWarmAirFurnace
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    served = model.getAirLoopHVACs.flat_map { |loop| loop.thermalZones.map(&:nameString) }
    served += model.getZoneHVACUnitHeaters.map { |unit| unit.thermalZone.get.nameString }
    assert_equal(zone_names.sort, served.sort)
    assert_equal(zone_names.size, model.getCoilHeatingGass.size)
    assert_empty(model.getCoilCoolingDXSingleSpeeds)
    assert_empty(model.getCoilCoolingWaters)
    assert_no_new_plants(model)
  end
end