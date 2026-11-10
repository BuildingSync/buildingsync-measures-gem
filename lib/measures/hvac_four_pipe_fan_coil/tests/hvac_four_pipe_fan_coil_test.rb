require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacFourPipeFanCoilTest < HvacMeasureTest
  MEASURE_CLASS = HvacFourPipeFanCoil
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    units = assert_zone_units(model, :getZoneHVACFourPipeFanCoils, zone_names)
    units.each do |unit|
      assert(unit.heatingCoil.to_CoilHeatingWater.is_initialized)
      assert(unit.coolingCoil.to_CoilCoolingWater.is_initialized)
    end
    assert_operator(model.getPlantLoops.size, :>=, 2)
    assert_water_coils_connected(model)
  end
end