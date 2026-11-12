require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacPackagedRooftopVavHwReheatTest < HvacMeasureTest
  MEASURE_CLASS = HvacPackagedRooftopVavHwReheat
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    assert_air_service(model, zone_names)
    terminals = model.getAirTerminalSingleDuctVAVReheats
    assert_equal(zone_names.size, terminals.size)
    terminals.each { |terminal| assert(terminal.reheatCoil.to_CoilHeatingWater.is_initialized) }
    refute_empty(model.getCoilCoolingDXTwoSpeeds)
    assert_water_coils_connected(model)
  end
end