require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacRadiantTest < HvacMeasureTest
  MEASURE_CLASS = HvacRadiant
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    units = model.getZoneHVACLowTempRadiantVarFlows + model.getZoneHVACLowTempRadiantConstFlows
    assert_equal(zone_names.size, units.size)
    assert_equal(zone_names.sort, units.map { |unit| unit.thermalZone.get.nameString }.sort)
    units.each do |unit|
      refute_empty(unit.surfaces)
      assert(unit.heatingCoil.is_initialized)
      assert(unit.coolingCoil.is_initialized)
    end
    assert_operator(model.getPlantLoops.size, :>=, 2)
  end

  def test_rejects_zone_without_surfaces
    zone('Zone One').spaces.each { |space| space.surfaces.each(&:remove) }
    assert_rejected_without_changes({'target_zone_names' => 'Zone One'}, error: /surfaces/i)
  end
end