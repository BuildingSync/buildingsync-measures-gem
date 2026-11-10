require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_modifier_tests'
require_relative '../measure'

class ModifyExistingPlantEquipmentTest < HvacMeasureTest
  MEASURE_CLASS = ModifyExistingPlantEquipment
  TEST_DIR = __dir__
  SCOPE_ARGUMENT = 'target_plant_equipment_names'
  ARGUMENT_NAMES = %w[target_plant_equipment_names property value].freeze
  include HvacModifierTests

  def valid_arguments
    {SCOPE_ARGUMENT => 'Boiler One', 'property' => 'boiler_thermal_efficiency', 'value' => 0.91}
  end

  {
    'boiler_capacity_kw' => [:getBoilerHotWaters, 'Boiler', :nominalCapacity, 125.0, 125_000.0],
    'boiler_thermal_efficiency' => [:getBoilerHotWaters, 'Boiler', :nominalThermalEfficiency, 0.91, 0.91],
    'chiller_capacity_tons' => [:getChillerElectricEIRs, 'Chiller', :referenceCapacity, 25.0, 87_921.321],
    'chiller_reference_cop' => [:getChillerElectricEIRs, 'Chiller', :referenceCOP, 5.7, 5.7]
  }.each do |property, (getter, prefix, field, value, expected)|
    define_method("test_#{property}_and_scope") do
      untouched = named(getter, "#{prefix} Two").to_s
      handles = @model.getModelObjects.map { |object| object.handle.to_s }.sort
      run_measure(SCOPE_ARGUMENT => " #{prefix} One, #{prefix} One, ", 'property' => property, 'value' => value)
      actual = named(getter, "#{prefix} One").public_send(field)
      actual = actual.get if actual.respond_to?(:get)
      assert_in_delta(expected, actual, 1e-6)
      assert_equal(untouched, named(getter, "#{prefix} Two").to_s)
      assert_equal(handles, @model.getModelObjects.map { |object| object.handle.to_s }.sort)
    end
  end

  def test_updates_multiple_boilers
    run_measure(valid_arguments.merge(SCOPE_ARGUMENT => 'Boiler One, Boiler Two'))
    @model.getBoilerHotWaters.each { |boiler| assert_in_delta(0.91, boiler.nominalThermalEfficiency, 1e-9) }
  end

  def test_rejects_nonpositive_value
    assert_rejected_without_changes(valid_arguments.merge('value' => 0.0), error: /greater than zero/)
    assert_rejected_without_changes(valid_arguments.merge('value' => -5.0), error: /greater than zero/)
  end

  def test_rejects_efficiency_above_one
    assert_rejected_without_changes(valid_arguments.merge('value' => 1.01), error: /must be in/)
  end

  def test_rejects_unsupported_equipment_property
    assert_rejected_without_changes(valid_arguments.merge(SCOPE_ARGUMENT => 'Chiller One'), error: /None.*supports/)
  end

  def test_warns_and_preserves_incompatible_named_equipment
    untouched = named(:getChillerElectricEIRs, 'Chiller One').to_s
    result = run_measure(valid_arguments.merge(SCOPE_ARGUMENT => 'Boiler One, Chiller One'))
    assert_match(/does not support/, result.warnings.map(&:logMessage).join)
    assert_in_delta(0.91, named(:getBoilerHotWaters, 'Boiler One').nominalThermalEfficiency, 1e-9)
    assert_equal(untouched, named(:getChillerElectricEIRs, 'Chiller One').to_s)
  end
end