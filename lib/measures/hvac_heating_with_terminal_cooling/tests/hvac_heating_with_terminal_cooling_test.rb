require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_measure_test'
require_relative '../measure'

class HvacHeatingWithTerminalCoolingTest < HvacMeasureTest
  MEASURE_CLASS = HvacHeatingWithTerminalCooling
  TEST_DIR = __dir__

  def test_argument_contract
    arguments = @measure.arguments(@model)
    assert_equal(%w[operation target_zone_names standards_template heating_source boiler_fuel], arguments.map(&:name))
    assert_equal(%w[create], arguments[0].choiceValues.to_a)
    assert_equal(HvacHeatingWithTerminalCooling::HEATING_SOURCES, arguments[3].choiceValues.to_a)
    assert_equal('central_gas_furnace', arguments[3].defaultValueAsString)
  end

  def test_central_gas_furnace_with_cooling_only_ptacs
    run_measure
    ptacs = assert_cooling_only_ptacs(ZONE_NAMES)
    assert_air_service(@model, ZONE_NAMES)
    air_loop = @model.getAirLoopHVACs.first
    assert_equal(1, @model.getCoilHeatingGass.count { |coil| coil.airLoopHVAC.is_initialized })
    assert(air_loop.airLoopHVACOutdoorAirSystem.is_initialized)
    ptacs.each { |unit| assert_in_delta(0.0, unit.outdoorAirFlowRateDuringCoolingOperation.get, 1e-9) }
    assert_no_new_plants(@model)
    ZONE_NAMES.each do |zone_name|
      zone = zone(zone_name)
      assert(zone.equipmentInCoolingOrder.first.to_ZoneHVACPackagedTerminalAirConditioner.is_initialized)
      assert(zone.equipmentInHeatingOrder.first.to_AirTerminalSingleDuctConstantVolumeNoReheat.is_initialized)
    end
    assert_translates_as_served(ZONE_NAMES)
  end

  def test_hot_water_baseboard_with_cooling_only_ptacs
    run_measure('heating_source' => 'hot_water_baseboard', 'target_zone_names' => 'Zone One, Zone Two')
    assert_cooling_only_ptacs(ZONE_NAMES.first(2))
    assert_zone_units(@model, :getZoneHVACBaseboardConvectiveWaters, ZONE_NAMES.first(2))
    assert_equal(1, @model.getBoilerHotWaters.size)
    assert_water_coils_connected_to_baseboards
    assert_empty(zone('Zone Three').equipment)
    assert_translates_as_served(ZONE_NAMES.first(2))
  end

  def test_electric_baseboard_with_cooling_only_ptacs
    run_measure('heating_source' => 'electric_baseboard', 'standards_template' => '90.1-2013')
    assert_cooling_only_ptacs(ZONE_NAMES)
    assert_zone_units(@model, :getZoneHVACBaseboardConvectiveElectrics, ZONE_NAMES)
    assert_no_new_plants(@model)
    assert_empty(@model.getAirLoopHVACs)
  end

  def test_hot_water_ptac_coils
    run_measure('heating_source' => 'hot_water_ptac_coil', 'boiler_fuel' => 'Electricity')
    units = assert_zone_units(@model, :getZoneHVACPackagedTerminalAirConditioners, ZONE_NAMES)
    units.each { |unit| assert(unit.heatingCoil.to_CoilHeatingWater.is_initialized) }
    assert_water_coils_connected(@model)
    assert_equal('Electricity', @model.getBoilerHotWaters.first.fuelType)
    assert_empty(@model.getZoneHVACBaseboardConvectiveWaters)
  end

  def test_rejects_create_on_served_zone
    add_baseboard('Zone Two')
    assert_rejected_without_changes({'target_zone_names' => 'Zone One, Zone Two'}, error: /requires unserved zones.*Zone Two/)
  end

  def test_rejects_missing_zone_before_changes
    assert_rejected_without_changes({'target_zone_names' => 'Zone One, Missing Zone'}, error: /not found.*Missing Zone/i)
  end

  private

  # Each PTAC cools with DX and keeps a zero-capacity, always-off electric heating placeholder.
  def assert_cooling_only_ptacs(zone_names)
    units = assert_zone_units(@model, :getZoneHVACPackagedTerminalAirConditioners, zone_names)
    units.each do |unit|
      assert(unit.coolingCoil.to_CoilCoolingDXSingleSpeed.is_initialized)
      coil = unit.heatingCoil.to_CoilHeatingElectric
      assert(coil.is_initialized)
      assert_in_delta(0.0, coil.get.nominalCapacity.get, 1e-9)
      assert_equal(@model.alwaysOffDiscreteSchedule.handle.to_s, coil.get.availabilitySchedule.handle.to_s)
    end
    units
  end

  def assert_water_coils_connected_to_baseboards
    coils = @model.getCoilHeatingWaterBaseboards
    refute_empty(coils)
    coils.each { |coil| assert(coil.plantLoop.is_initialized, "Unconnected coil: #{coil.nameString}") }
  end
end
