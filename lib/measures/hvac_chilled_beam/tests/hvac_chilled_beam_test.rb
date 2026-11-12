require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacChilledBeamTest < HvacMeasureTest
  MEASURE_CLASS = HvacChilledBeam
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    assert_air_service(model, zone_names)
    assert_equal(zone_names.size, model.getAirTerminalSingleDuctConstantVolumeFourPipeBeams.size)
    assert_empty(model.getZoneHVACFourPipeFanCoils)
    coils = model.getCoilCoolingFourPipeBeams + model.getCoilHeatingFourPipeBeams
    assert_equal(2 * zone_names.size, coils.size)
    coils.each { |coil| assert(coil.plantLoop.is_initialized) }
    assert_water_coils_connected(model)
    assert_includes(model.getCoilCoolingWaters.map(&:nameString), 'Chilled-Beam Primary Air Cooling Coil')
  end
end