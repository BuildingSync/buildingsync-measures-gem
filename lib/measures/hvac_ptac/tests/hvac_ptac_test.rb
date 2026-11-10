require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacPtacTest < HvacMeasureTest
  MEASURE_CLASS = HvacPtac
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    units = assert_zone_units(model, :getZoneHVACPackagedTerminalAirConditioners, zone_names)
    units.each do |unit|
      assert(unit.heatingCoil.to_CoilHeatingElectric.is_initialized)
      assert(unit.coolingCoil.to_CoilCoolingDXSingleSpeed.is_initialized)
    end
    assert_no_new_plants(model)
  end
end