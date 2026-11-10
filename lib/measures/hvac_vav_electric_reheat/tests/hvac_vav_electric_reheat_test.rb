require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacVavElectricReheatTest < HvacMeasureTest
  MEASURE_CLASS = HvacVavElectricReheat
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    assert_air_service(model, zone_names)
    terminals = model.getAirTerminalSingleDuctParallelPIUReheats
    assert_equal(zone_names.size, terminals.size)
    terminals.each { |terminal| assert(terminal.reheatCoil.to_CoilHeatingElectric.is_initialized) }
    refute_empty(model.getChillerElectricEIRs)
    assert_water_coils_connected(model)
  end
end