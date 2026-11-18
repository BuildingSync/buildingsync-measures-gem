require 'openstudio'
require 'minitest/autorun'
require_relative '../measure'

# Self-contained so the tests run from a standalone copy of this measure. Applying a topology
# itself still requires the hvac_* measures in the same measures directory.
class ApplyHvacTopologyToZoneScopeTest < Minitest::Test
  MEASURE_CLASS = ApplyHvacTopologyToZoneScope
  ZONE_NAMES = ['Zone One', 'Zone Two', 'Zone Three'].freeze

  def setup
    @measure = MEASURE_CLASS.new
    translated = OpenStudio::OSVersion::VersionTranslator.new.loadModel(OpenStudio::Path.new(File.join(__dir__, 'test_model.osm')))
    assert(translated.is_initialized, 'Cannot load test_model.osm')
    @model = translated.get
  end

  def run_measure(values = {}, expected: 'Success', error: nil, **argument_values)
    values = values.merge(argument_values)
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    arguments = OpenStudio::Measure.convertOSArgumentVectorToMap(@measure.arguments(@model))
    values.each do |key, value|
      argument = arguments[key].clone
      assert(argument.setValue(value), "Cannot set #{key}=#{value.inspect}")
      arguments[key] = argument
    end
    returned = @measure.run(@model, runner, arguments)
    result = runner.result
    errors = result.errors.map(&:logMessage).join("\n")
    assert_equal(expected, result.value.valueName, errors)
    assert_equal(expected != 'Fail', returned, errors)
    assert_match(error, errors) if error
    result
  end

  def zone(zone_name)
    found = @model.getThermalZoneByName(zone_name)
    assert(found.is_initialized, "Missing zone: #{zone_name}")
    found.get
  end

  def snapshot
    @model.getModelObjects.map(&:to_s).sort
  end

  def assert_rejected_without_changes(values, error:)
    before = snapshot
    run_measure(values, expected: 'Fail', error: error)
    assert_equal(before, snapshot, 'Rejected input must not partially modify the model')
  end

  def add_baseboard(zone_name)
    baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(@model)
    assert(baseboard.addToThermalZone(zone(zone_name)))
  end

  def add_air_loop(zone_names)
    air_loop = OpenStudio::Model::AirLoopHVAC.new(@model)
    OpenStudio::Model::FanConstantVolume.new(@model).addToNode(air_loop.supplyOutletNode)
    zone_names.each { |zone_name| assert(air_loop.addBranchForZone(zone(zone_name))) }
  end

  def assert_zone_units(model, getter, zone_names)
    units = model.public_send(getter)
    assert_equal(zone_names.sort, units.map { |unit| unit.thermalZone.get.nameString }.sort)
  end

  def assert_translates_as_served(zone_names)
    translator = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = translator.translateModel(@model)
    assert_empty(translator.errors.map(&:logMessage))
    connected = workspace.getObjectsByType('ZoneHVAC:EquipmentConnections'.to_IddObjectType)
                         .map { |object| object.getString(0).get.upcase }
    zone_names.each { |zone_name| assert_includes(connected, zone_name.upcase) }
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
