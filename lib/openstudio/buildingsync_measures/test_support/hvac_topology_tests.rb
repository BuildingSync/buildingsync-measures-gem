require_relative 'hvac_measure_test'

# Included in each concrete local suite; assert_system is specific to its topology.
module HvacTopologyTests
  ZONE_NAMES = HvacMeasureTest::ZONE_NAMES

  def ventilation_only?
    false
  end

  def test_argument_contract
    arguments = @measure.arguments(@model)
    assert_equal(%w[operation target_zone_names standards_template], arguments.first(3).map(&:name))
    assert_equal(%w[create replace], arguments[0].choiceValues.to_a)
    assert_equal('create', arguments[0].defaultValueAsString)
    assert_equal('', arguments[1].defaultValueAsString)
    assert_equal(['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010',
                  '90.1-2013', '90.1-2016', '90.1-2019'], arguments[2].choiceValues.to_a)
    assert_equal('90.1-2019', arguments[2].defaultValueAsString)
  end

  def test_create_with_each_older_template
    ['DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004', '90.1-2007', '90.1-2010'].each do |template|
      setup
      run_measure('standards_template' => template)
      assert_system(@model, ZONE_NAMES)
    end
  end

  def test_default_create_and_forward_translation
    run_measure
    assert_system(@model, ZONE_NAMES)
    assert_translates_as_served(ZONE_NAMES)
  end

  def test_explicit_scope_with_2013_template
    untouched = add_baseboard('Zone Three').to_s
    run_measure('target_zone_names' => ' Zone One, Zone Two, Zone One, ', 'standards_template' => '90.1-2013')
    assert_system(@model, ZONE_NAMES.first(2))
    assert_equal(untouched, named(:getZoneHVACBaseboardConvectiveElectrics, 'Zone Three Existing Baseboard').to_s)
    assert(zone('Zone Three').airLoopHVAC.empty?)
  end

  def test_single_zone_with_2016_template
    run_measure('target_zone_names' => 'Zone Two', 'standards_template' => '90.1-2016')
    assert_system(@model, ['Zone Two'])
    %w[One Three].each do |suffix|
      assert_empty(zone("Zone #{suffix}").equipment)
      assert(zone("Zone #{suffix}").airLoopHVAC.empty?)
    end
  end

  def test_replace_selected_equipment_preserves_others
    ZONE_NAMES.each { |zone_name| add_baseboard(zone_name) }
    untouched = named(:getZoneHVACBaseboardConvectiveElectrics, 'Zone Three Existing Baseboard').to_s
    old_loop_handle = add_air_loop(ZONE_NAMES.first(2)).handle.to_s
    preserved_plant = OpenStudio::Model::PlantLoop.new(@model)
    preserved_plant.setName('Unrelated Existing Plant')
    plant_handle = preserved_plant.handle.to_s

    run_measure('operation' => 'replace', 'target_zone_names' => 'Zone One, Zone Two')
    assert_system(@model, ZONE_NAMES.first(2))
    refute_includes(@model.getAirLoopHVACs.map { |loop| loop.handle.to_s }, old_loop_handle)
    assert_includes(@model.getPlantLoops.map { |loop| loop.handle.to_s }, plant_handle)
    assert_equal(untouched, named(:getZoneHVACBaseboardConvectiveElectrics, 'Zone Three Existing Baseboard').to_s)
    expected_names = ventilation_only? ? ZONE_NAMES : ['Zone Three']
    assert_equal(expected_names.map { |item| "#{item} Existing Baseboard" }.sort,
                 @model.getZoneHVACBaseboardConvectiveElectrics.map(&:nameString).sort)
  end

  def test_rejects_create_on_served_zone
    add_air_loop(['Zone One'])
    assert_rejected_without_changes({'target_zone_names' => 'Zone One'}, error: /creation requires/i)
  end

  def test_rejects_partial_shared_loop_replacement
    add_air_loop(ZONE_NAMES.first(2))
    assert_rejected_without_changes({'operation' => 'replace', 'target_zone_names' => 'Zone One'},
                                    error: /partially remove shared air loops/i)
  end

  def test_json_scope_binds_names_containing_commas
    zone('Zone One').setName('Zone One, East')
    run_measure('target_zone_names' => '["Zone One, East", "Zone Two", "Zone Two"]')
    assert_system(@model, ['Zone One, East', 'Zone Two'])
    assert(zone('Zone Three').airLoopHVAC.empty?)
  end

  def test_rejects_invalid_json_scope
    ['["Zone One"', '["Zone One", 2]'].each do |text|
      assert_rejected_without_changes({'target_zone_names' => text}, error: /JSON array of strings/)
    end
  end

  def test_rejects_missing_zone_before_changes
    assert_rejected_without_changes({'target_zone_names' => 'Zone One, Missing Zone'}, error: /not found.*Missing Zone/i)
  end

  def test_rejects_blank_replace_scope
    add_baseboard('Zone One')
    assert_rejected_without_changes({'operation' => 'replace', 'target_zone_names' => ''}, error: /Replace requires/)
  end

  def test_rejects_model_without_zones
    @model = OpenStudio::Model::Model.new
    assert_rejected_without_changes({}, error: /No target thermal zones/)
  end
end

module HvacVentilationTests
  def ventilation_only?
    true
  end

  def test_keeps_zone_units_and_disables_duplicate_outdoor_air
    fan = OpenStudio::Model::FanOnOff.new(@model)
    heating = OpenStudio::Model::CoilHeatingElectric.new(@model)
    cooling = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(@model)
    unit = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(
      @model, @model.alwaysOnDiscreteSchedule, fan, heating, cooling
    )
    unit.addToThermalZone(zone('Zone One'))
    unit.setOutdoorAirFlowRateDuringCoolingOperation(0.1)
    unit.setOutdoorAirFlowRateDuringHeatingOperation(0.1)
    unit.setOutdoorAirFlowRateWhenNoCoolingorHeatingisNeeded(0.1)
    handle = unit.handle.to_s
    run_measure('target_zone_names' => 'Zone One')
    assert_system(@model, ['Zone One'])
    units = @model.getZoneHVACPackagedTerminalAirConditioners
    assert_equal([handle], units.map { |item| item.handle.to_s })
    unit = units.first
    [unit.outdoorAirFlowRateDuringCoolingOperation, unit.outdoorAirFlowRateDuringHeatingOperation,
     unit.outdoorAirFlowRateWhenNoCoolingorHeatingisNeeded].each { |flow| assert_in_delta(0.0, flow.get, 1e-9) }
  end

  def assert_system(model, zone_names)
    assert_air_service(model, zone_names)
    air_loop = model.getAirLoopHVACs.first
    assert_equal('VentilationRequirement', air_loop.sizingSystem.typeofLoadtoSizeOn)
    assert(air_loop.airLoopHVACOutdoorAirSystem.is_initialized)
    supply_fans = air_loop.supplyComponents.select { |component| component.to_FanSystemModel.is_initialized }
    assert_equal(1, supply_fans.size, 'Expected one FanSystemModel connected to the ventilation air loop supply path')
    assert_equal(zone_names.size, model.getAirTerminalSingleDuctConstantVolumeNoReheats.size)
    zone_names.each do |zone_name|
      target = zone(zone_name, model)
      assert(target.equipmentInCoolingOrder.first.to_AirTerminalSingleDuctConstantVolumeNoReheat.is_initialized)
      assert(target.equipmentInHeatingOrder.first.to_AirTerminalSingleDuctConstantVolumeNoReheat.is_initialized)
    end
  end
end