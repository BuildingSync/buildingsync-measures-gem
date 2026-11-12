require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacVrfTest < HvacMeasureTest
  MEASURE_CLASS = HvacVrf
  TEST_DIR = __dir__
  include HvacTopologyTests

  def assert_system(model, zone_names)
    terminals = assert_zone_units(model, :getZoneHVACTerminalUnitVariableRefrigerantFlows, zone_names)
    assert_equal(1, model.getAirConditionerVariableRefrigerantFlows.size)
    assert_equal(terminals.map { |terminal| terminal.handle.to_s }.sort,
                 model.getAirConditionerVariableRefrigerantFlows.first.terminals.map { |terminal| terminal.handle.to_s }.sort)
    assert_no_new_plants(model)
  end

  def test_rejects_partial_outdoor_unit_replacement
    outdoor_unit = OpenStudio::Model::AirConditionerVariableRefrigerantFlow.new(@model)
    ZONE_NAMES.first(2).each do |zone_name|
      terminal = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(@model)
      terminal.addToThermalZone(zone(zone_name))
      outdoor_unit.addTerminal(terminal)
    end
    assert_rejected_without_changes({'operation' => 'replace', 'target_zone_names' => 'Zone One'}, error: /shared VRF/i)
  end
end