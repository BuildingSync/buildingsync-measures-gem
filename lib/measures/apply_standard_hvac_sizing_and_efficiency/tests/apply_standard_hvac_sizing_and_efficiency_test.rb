require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_measure_test'
require_relative '../measure'

# The success path needs a sizing run (EnergyPlus and design days); it is covered by BOSS
# baseline simulations. These tests cover arguments and the input checks.
class ApplyStandardHvacSizingAndEfficiencyTest < HvacMeasureTest
  MEASURE_CLASS = ApplyStandardHvacSizingAndEfficiency
  TEST_DIR = __dir__

  def setup
    @measure = MEASURE_CLASS.new
    @model = load_model(File.join(__dir__, '..', '..', 'hvac_ptac', 'tests', 'test_model.osm'))
    @run_number = 0
  end

  def test_arguments
    assert_equal(%w[standards_template add_infiltration_schedules], @measure.arguments(@model).map(&:name))
  end

  def test_model_without_hvac_fails
    @model.getAirLoopHVACs.each(&:remove)
    @model.getThermalZones.each { |zone| zone.equipment.each(&:remove) }
    run_measure({}, expected: 'Fail', error: /no HVAC/)
  end

  def test_model_without_standards_building_type_fails
    add_baseboard('Zone Two')
    @model.getBuilding.resetStandardsBuildingType
    run_measure({}, expected: 'Fail', error: /standards building type/)
  end
end
