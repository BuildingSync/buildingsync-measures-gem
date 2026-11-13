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
    assert_equal(%w[topology_measure operation zone_scope zone_names_json standards_template topology_arguments_json], arguments)
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

  def test_zone_names_with_commas_bind_exactly
    zone('Zone One').setName('Zone One, East')
    names = @model.getThermalZones.map(&:nameString)
    assert_includes(names, 'Zone One, East')
    run_measure('topology_measure' => 'hvac_ptac')
    assert_zone_units(@model, :getZoneHVACPackagedTerminalAirConditioners, names)
  end

  def test_explicit_zone_names_bind_only_listed_zones
    zone('Zone One').setName('Zone One, East')
    run_measure('topology_measure' => 'hvac_ptac', 'zone_scope' => 'explicit_zone_names',
                'zone_names_json' => '["Zone One, East", "Zone Three"]')
    assert_zone_units(@model, :getZoneHVACPackagedTerminalAirConditioners, ['Zone One, East', 'Zone Three'])
  end

  def test_explicit_zone_names_reject_missing_and_invalid_lists
    explicit = { 'topology_measure' => 'hvac_ptac', 'zone_scope' => 'explicit_zone_names' }
    assert_rejected_without_changes(explicit.merge('zone_names_json' => '["Zone One", "Missing Zone"]'), error: /not found: Missing Zone/)
    ['', '[]', 'Zone One', '["Zone One", 2]', '{"a": "b"}'].each do |text|
      assert_rejected_without_changes(explicit.merge('zone_names_json' => text), error: /JSON array/)
    end
  end

  def test_topology_arguments_json_forwards_extra_arguments
    result = run_measure('topology_measure' => 'hvac_packaged_rooftop_heat_pump',
                         'topology_arguments_json' => '{"supplemental_heating_fuel":"NaturalGas"}')
    assert_includes(result.finalCondition.get.logMessage, 'NaturalGas supplemental heat')
  end

  def test_topology_arguments_json_rejects_invalid_reserved_and_unknown_arguments
    base = { 'topology_measure' => 'hvac_ptac' }
    ['[]', '{"a": 1}', 'not json', '{"operation":"replace"}', '{"target_zone_names":"[]"}'].each do |text|
      assert_rejected_without_changes(base.merge('topology_arguments_json' => text), error: /topology_arguments_json/)
    end
    assert_rejected_without_changes(base.merge('topology_arguments_json' => '{"no_such_argument":"x"}'), error: /Unknown argument/)
  end

  def test_model_without_zones_fails
    @model.getThermalZones.each(&:remove)
    assert_rejected_without_changes({ 'topology_measure' => 'hvac_ptac' }, error: /no thermal zones/)
  end
end
