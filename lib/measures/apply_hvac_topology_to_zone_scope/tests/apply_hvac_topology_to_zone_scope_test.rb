require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_measure_test'
require_relative '../measure'

class ApplyHvacTopologyToZoneScopeTest < HvacMeasureTest
  MEASURE_CLASS = ApplyHvacTopologyToZoneScope
  TEST_DIR = __dir__

  # Reuse the three-zone topology fixture instead of checking in a copy.
  def setup
    @measure = MEASURE_CLASS.new
    @model = load_model(File.join(__dir__, '..', '..', 'hvac_ptac', 'tests', 'test_model.osm'))
    @run_number = 0
  end

  def test_arguments
    arguments = @measure.arguments(@model).map(&:name)
    assert_equal(%w[topology_measure operation zone_scope standards_template], arguments)
    topology_dirs = Dir.glob(File.join(__dir__, '..', '..', 'hvac_*')).map { |dir| File.basename(dir) }.sort
    assert_equal(topology_dirs, MEASURE_CLASS::TOPOLOGY_MEASURES.sort)
  end

  def test_create_binds_every_model_zone_by_exact_name
    result = run_measure('topology_measure' => 'hvac_ptac', 'standards_template' => '90.1-2016')
    assert_zone_units(@model, :getZoneHVACPackagedTerminalAirConditioners, ZONE_NAMES)
    assert_includes(result.info.map(&:logMessage).join("\n"), 'Zone One, Zone Three, Zone Two')
    assert_translates_as_served(ZONE_NAMES)
  end

  def test_replace_covers_a_shared_air_loop_with_full_scope
    add_air_loop(ZONE_NAMES)
    run_measure('topology_measure' => 'hvac_pthp', 'operation' => 'replace')
    assert_empty(@model.getAirLoopHVACs)
    assert_zone_units(@model, :getZoneHVACPackagedTerminalHeatPumps, ZONE_NAMES)
  end

  def test_create_keeps_topology_safety_checks
    add_baseboard('Zone Two')
    assert_rejected_without_changes({ 'topology_measure' => 'hvac_ptac' }, error: /Zone Two/)
  end

  def test_model_without_zones_fails
    @model.getThermalZones.each(&:remove)
    assert_rejected_without_changes({ 'topology_measure' => 'hvac_ptac' }, error: /no thermal zones/)
  end
end
