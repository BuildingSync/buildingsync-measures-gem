require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacGroundSourceHeatPumpTest < HvacMeasureTest
  MEASURE_CLASS = HvacGroundSourceHeatPump
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    assert_zone_units(model, :getZoneHVACWaterToAirHeatPumps, zone_names)
    coils = model.getCoilHeatingWaterToAirHeatPumpEquationFits + model.getCoilCoolingWaterToAirHeatPumpEquationFits
    assert_equal(2 * zone_names.size, coils.size)
    coils.each { |coil| assert(coil.plantLoop.is_initialized) }
    refute_empty(model.getPlantLoops)
    refute_empty(model.getPlantComponentTemperatureSources)
  end
end