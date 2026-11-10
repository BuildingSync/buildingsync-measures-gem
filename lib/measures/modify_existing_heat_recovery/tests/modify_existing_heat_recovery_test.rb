require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_modifier_tests'
require_relative '../measure'

class ModifyExistingHeatRecoveryTest < HvacMeasureTest
  MEASURE_CLASS = ModifyExistingHeatRecovery
  TEST_DIR = __dir__
  SCOPE_ARGUMENT = 'target_heat_exchanger_names'
  ARGUMENT_NAMES = %w[target_heat_exchanger_names effectiveness_metric effectiveness].freeze
  FIELDS = %w[100Cooling 75Cooling 100Heating 75Heating].freeze
  include HvacModifierTests

  def valid_arguments
    {SCOPE_ARGUMENT => 'ERV One', 'effectiveness_metric' => 'sensible_effectiveness', 'effectiveness' => 0.77}
  end

  %w[sensible latent].each do |metric|
    {zero: 0.0, nominal: 0.77, one: 1.0}.each do |label, value|
      define_method("test_#{metric}_#{label}_and_scope") do
        untouched = named(:getHeatExchangerAirToAirSensibleAndLatents, 'ERV Two').to_s
        other_metric = metric == 'sensible' ? 'latent' : 'sensible'
        before = FIELDS.map do |suffix|
          named(:getHeatExchangerAirToAirSensibleAndLatents, 'ERV One').public_send("#{other_metric}Effectivenessat#{suffix}AirFlow")
        end
        run_measure(SCOPE_ARGUMENT => 'ERV One', 'effectiveness_metric' => "#{metric}_effectiveness", 'effectiveness' => value)
        target = named(:getHeatExchangerAirToAirSensibleAndLatents, 'ERV One')
        FIELDS.each { |suffix| assert_in_delta(value, target.public_send("#{metric}Effectivenessat#{suffix}AirFlow"), 1e-9) }
        assert_equal(before, FIELDS.map { |suffix| target.public_send("#{other_metric}Effectivenessat#{suffix}AirFlow") })
        assert_equal(untouched, named(:getHeatExchangerAirToAirSensibleAndLatents, 'ERV Two').to_s)
      end
    end

    define_method("test_#{metric}_disable_twice_and_restore") do
      [0.0, 0.0, 0.72].each do |value|
        run_measure(SCOPE_ARGUMENT => 'ERV One', 'effectiveness_metric' => "#{metric}_effectiveness", 'effectiveness' => value)
        target = named(:getHeatExchangerAirToAirSensibleAndLatents, 'ERV One')
        FIELDS.each { |suffix| assert_in_delta(value, target.public_send("#{metric}Effectivenessat#{suffix}AirFlow"), 1e-9) }
      end
    end
  end

  def test_multiple_names_and_duplicates
    run_measure(valid_arguments.merge(SCOPE_ARGUMENT => ' ERV One, ERV Two, ERV One, '))
    @model.getHeatExchangerAirToAirSensibleAndLatents.each do |exchanger|
      FIELDS.each { |suffix| assert_in_delta(0.77, exchanger.public_send("sensibleEffectivenessat#{suffix}AirFlow"), 1e-9) }
    end
  end

  def test_rejects_out_of_range_effectiveness
    [-0.01, 1.01].each do |value|
      assert_rejected_without_changes(valid_arguments.merge('effectiveness' => value), error: /effectiveness in/)
    end
  end

  def test_rejects_unsupported_curve_before_any_update
    exchanger = named(:getHeatExchangerAirToAirSensibleAndLatents, 'ERV Two')
    assert(exchanger.setSensibleEffectivenessofCoolingAirFlowCurve(OpenStudio::Model::CurveLinear.new(@model)))
    assert_rejected_without_changes(valid_arguments.merge(SCOPE_ARGUMENT => 'ERV One, ERV Two'), error: /non-TableLookup/)
  end
end