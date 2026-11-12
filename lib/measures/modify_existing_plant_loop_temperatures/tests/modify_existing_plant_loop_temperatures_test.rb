require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_modifier_tests'
require_relative '../measure'

class ModifyExistingPlantLoopTemperaturesTest < HvacMeasureTest
  MEASURE_CLASS = ModifyExistingPlantLoopTemperatures
  TEST_DIR = __dir__
  SCOPE_ARGUMENT = 'target_plant_loop_names'
  ARGUMENT_NAMES = %w[target_plant_loop_names design_loop_exit_temperature_c].freeze
  include HvacModifierTests

  def valid_arguments
    {SCOPE_ARGUMENT => 'Heating Loop One', 'design_loop_exit_temperature_c' => 55.0}
  end

  {heating: ['Heating Loop One', 55.0], chilled: ['Cooling Loop One', 6.7], radiant: ['Cooling Loop One', 15.6]}.each do |label, (target, value)|
    define_method("test_#{label}_temperature_and_scope") do
      before = @model.getPlantLoops.reject { |loop| loop.nameString == target }
                     .to_h { |loop| [loop.nameString, loop.sizingPlant.to_s] }
      run_measure(SCOPE_ARGUMENT => target, 'design_loop_exit_temperature_c' => value)
      assert_in_delta(value, named(:getPlantLoops, target).sizingPlant.designLoopExitTemperature, 1e-9)
      before.each { |name, sizing| assert_equal(sizing, named(:getPlantLoops, name).sizingPlant.to_s) }
    end
  end

  def test_multiple_names_and_duplicates
    run_measure(valid_arguments.merge(SCOPE_ARGUMENT => ' Heating Loop One, Heating Loop Two, Heating Loop One, '))
    %w[One Two].each do |suffix|
      assert_in_delta(55.0, named(:getPlantLoops, "Heating Loop #{suffix}").sizingPlant.designLoopExitTemperature, 1e-9)
      assert_in_delta(7.0, named(:getPlantLoops, "Cooling Loop #{suffix}").sizingPlant.designLoopExitTemperature, 1e-9)
    end
  end
end