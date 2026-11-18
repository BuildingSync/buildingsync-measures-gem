require 'openstudio'
require 'minitest/autorun'
require_relative '../measure'

# The success path needs a sizing run (EnergyPlus and design days); it is covered by BOSS
# baseline simulations. These tests cover arguments and the input checks.
class ApplyStandardHvacSizingAndEfficiencyTest < Minitest::Test
  def setup
    @measure = ApplyStandardHvacSizingAndEfficiency.new
    translated = OpenStudio::OSVersion::VersionTranslator.new.loadModel(OpenStudio::Path.new(File.join(__dir__, 'test_model.osm')))
    assert(translated.is_initialized, 'Cannot load test_model.osm')
    @model = translated.get
  end

  def run_measure(_values, expected:, error:)
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    arguments = OpenStudio::Measure.convertOSArgumentVectorToMap(@measure.arguments(@model))
    returned = @measure.run(@model, runner, arguments)
    result = runner.result
    assert_equal(expected, result.value.valueName)
    refute(returned)
    assert_match(error, result.errors.map(&:logMessage).join("\n"))
  end

  def add_baseboard(zone_name)
    baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(@model)
    assert(baseboard.addToThermalZone(@model.getThermalZoneByName(zone_name).get))
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
