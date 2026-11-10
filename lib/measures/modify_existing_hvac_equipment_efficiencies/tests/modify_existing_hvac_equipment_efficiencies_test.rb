require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_modifier_tests'
require_relative '../measure'

class ModifyExistingHvacEquipmentEfficienciesTest < HvacMeasureTest
  MEASURE_CLASS = ModifyExistingHvacEquipmentEfficiencies
  TEST_DIR = __dir__
  SCOPE_ARGUMENT = 'target_object_names'
  ARGUMENT_NAMES = %w[target_object_names efficiency_metric efficiency_value].freeze
  include HvacModifierTests

  def valid_arguments
    {SCOPE_ARGUMENT => 'CoilHeatingElectric One', 'efficiency_metric' => 'electric_heating_efficiency', 'efficiency_value' => 0.96}
  end

  [
    ['dx_cooling_cop', 'CoilCoolingDXSingleSpeed', :getCoilCoolingDXSingleSpeeds, [:ratedCOP], 4.1],
    ['dx_cooling_cop', 'CoilCoolingDXTwoSpeed', :getCoilCoolingDXTwoSpeeds, [:ratedHighSpeedCOP, :ratedLowSpeedCOP], 4.1],
    ['dx_heating_cop', 'CoilHeatingDXSingleSpeed', :getCoilHeatingDXSingleSpeeds, [:ratedCOP], 3.8],
    ['gas_burner_efficiency', 'CoilHeatingGas', :getCoilHeatingGass, [:gasBurnerEfficiency], 0.93],
    ['electric_heating_efficiency', 'CoilHeatingElectric', :getCoilHeatingElectrics, [:efficiency], 0.96],
    ['water_to_air_cooling_cop', 'CoilCoolingWaterToAirHeatPumpEquationFit', :getCoilCoolingWaterToAirHeatPumpEquationFits,
     [:ratedCoolingCoefficientofPerformance], 4.2],
    ['water_to_air_heating_cop', 'CoilHeatingWaterToAirHeatPumpEquationFit', :getCoilHeatingWaterToAirHeatPumpEquationFits,
     [:ratedHeatingCoefficientofPerformance], 3.9],
    ['vrf_cooling_cop', 'AirConditionerVariableRefrigerantFlow', :getAirConditionerVariableRefrigerantFlows, [:ratedCoolingCOP], 4.3],
    ['vrf_heating_cop', 'AirConditionerVariableRefrigerantFlow', :getAirConditionerVariableRefrigerantFlows, [:ratedHeatingCOP], 4.0]
  ].each_with_index do |(metric, type, getter, fields, value), index|
    define_method("test_#{metric}_#{index}") do
      untouched = named(getter, "#{type} Two").to_s
      handles = @model.getModelObjects.map { |object| object.handle.to_s }.sort
      run_measure(SCOPE_ARGUMENT => "#{type} One", 'efficiency_metric' => metric, 'efficiency_value' => value)
      fields.each do |field|
        actual = named(getter, "#{type} One").public_send(field)
        actual = actual.get if actual.respond_to?(:get)
        assert_in_delta(value, actual, 1e-9)
      end
      assert_equal(untouched, named(getter, "#{type} Two").to_s)
      assert_equal(handles, @model.getModelObjects.map { |object| object.handle.to_s }.sort)
    end
  end

  def test_multiple_names_and_duplicates
    run_measure(valid_arguments.merge(SCOPE_ARGUMENT => ' CoilHeatingElectric One, CoilHeatingElectric Two, CoilHeatingElectric One, '))
    @model.getCoilHeatingElectrics.each { |coil| assert_in_delta(0.96, coil.efficiency, 1e-9) }
  end

  def test_rejects_invalid_fractional_efficiency
    [-0.1, 0.0, 1.01].each do |value|
      assert_rejected_without_changes(valid_arguments.merge('efficiency_value' => value), error: /fractional efficiencies/)
    end
  end

  def test_rejects_nonpositive_cop
    values = {SCOPE_ARGUMENT => 'CoilCoolingDXSingleSpeed One', 'efficiency_metric' => 'dx_cooling_cop'}
    [0.0, -1.0].each do |value|
      assert_rejected_without_changes(values.merge('efficiency_value' => value), error: /COP values must be greater than zero/)
    end
  end

  def test_rejects_incompatible_metric
    assert_rejected_without_changes(valid_arguments.merge('efficiency_metric' => 'dx_cooling_cop'), error: /None.*support/)
  end

  def test_warns_for_mixed_supported_and_unsupported_objects
    untouched = named(:getCoilHeatingGass, 'CoilHeatingGas One').to_s
    result = run_measure(valid_arguments.merge(SCOPE_ARGUMENT => 'CoilHeatingElectric One, CoilHeatingGas One'))
    assert_match(/does not support/, result.warnings.map(&:logMessage).join)
    assert_equal(untouched, named(:getCoilHeatingGass, 'CoilHeatingGas One').to_s)
    assert_in_delta(0.96, named(:getCoilHeatingElectrics, 'CoilHeatingElectric One').efficiency, 1e-9)
  end
end