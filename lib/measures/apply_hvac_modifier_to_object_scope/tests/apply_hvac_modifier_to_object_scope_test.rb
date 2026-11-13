require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_measure_test'
require_relative '../measure'

class ApplyHvacModifierToObjectScopeTest < HvacMeasureTest
  MEASURE_CLASS = ApplyHvacModifierToObjectScope
  TEST_DIR = __dir__

  # Reuse the three-zone topology fixture instead of checking in a copy.
  def setup
    @measure = MEASURE_CLASS.new
    @model = load_model(File.join(__dir__, '..', '..', 'hvac_ptac', 'tests', 'test_model.osm'))
    @run_number = 0
  end

  def add_dx_coil(name)
    coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(@model)
    coil.setName(name)
    coil.setRatedCOP(3.0)
    coil
  end

  def add_plant_loop(name, loop_type)
    plant_loop = OpenStudio::Model::PlantLoop.new(@model)
    plant_loop.setName(name)
    plant_loop.sizingPlant.setLoopType(loop_type)
    plant_loop.sizingPlant.setDesignLoopExitTemperature(50.0)
    plant_loop
  end

  def dx_cop(value)
    { 'modifier_measure' => 'modify_existing_hvac_equipment_efficiencies',
      'modifier_arguments_json' => JSON.generate('efficiency_metric' => 'dx_cooling_cop', 'efficiency_value' => value) }
  end

  def test_arguments
    arguments = @measure.arguments(@model).map(&:name)
    assert_equal(%w[modifier_measure object_scope object_names_json plant_loop_type modifier_arguments_json], arguments)
    modifier_dirs = Dir.glob(File.join(__dir__, '..', '..', 'modify_existing_*')).map { |dir| File.basename(dir) }.sort
    assert_equal(modifier_dirs, MEASURE_CLASS::MODIFIER_TARGETS.keys.sort)
  end

  def test_all_matching_objects_changes_every_object_of_the_metric_type
    add_dx_coil('DX One')
    add_dx_coil('DX Two')
    gas = OpenStudio::Model::CoilHeatingGas.new(@model)
    gas.setGasBurnerEfficiency(0.8)
    result = run_measure(dx_cop(4))
    @model.getCoilCoolingDXSingleSpeeds.each { |coil| assert_in_delta(4.0, coil.ratedCOP, 1e-9) }
    assert_in_delta(0.8, @model.getCoilHeatingGass.first.gasBurnerEfficiency, 1e-9)
    assert_includes(result.info.map(&:logMessage).join("\n"), 'DX One, DX Two')
  end

  def test_explicit_object_names_change_only_listed_objects
    add_dx_coil('DX One')
    add_dx_coil('DX Two')
    run_measure(dx_cop(4.5).merge('object_scope' => 'explicit_object_names', 'object_names_json' => '["DX Two"]'))
    assert_in_delta(3.0, named(:getCoilCoolingDXSingleSpeeds, 'DX One').ratedCOP, 1e-9)
    assert_in_delta(4.5, named(:getCoilCoolingDXSingleSpeeds, 'DX Two').ratedCOP, 1e-9)
  end

  def test_plant_loop_temperatures_filter_by_loop_type
    add_plant_loop('Hot Water Loop', 'Heating')
    add_plant_loop('Chilled Water Loop', 'Cooling')
    args = { 'modifier_measure' => 'modify_existing_plant_loop_temperatures',
             'modifier_arguments_json' => '{"design_loop_exit_temperature_c":60}' }
    assert_rejected_without_changes(args, error: /plant_loop_type/)
    run_measure(args.merge('plant_loop_type' => 'Heating'))
    assert_in_delta(60.0, named(:getPlantLoops, 'Hot Water Loop').sizingPlant.designLoopExitTemperature, 1e-9)
    assert_in_delta(50.0, named(:getPlantLoops, 'Chilled Water Loop').sizingPlant.designLoopExitTemperature, 1e-9)
  end

  def test_plant_equipment_matches_by_property_prefix
    boiler = OpenStudio::Model::BoilerHotWater.new(@model)
    boiler.setNominalThermalEfficiency(0.8)
    run_measure('modifier_measure' => 'modify_existing_plant_equipment',
                'modifier_arguments_json' => '{"property":"boiler_thermal_efficiency","value":0.92}')
    assert_in_delta(0.92, @model.getBoilerHotWaters.first.nominalThermalEfficiency, 1e-9)
  end

  def test_rejects_scope_with_no_matching_objects
    assert_rejected_without_changes(dx_cop(4), error: /no objects/)
  end

  def test_names_with_commas_are_passed_as_json
    add_dx_coil('DX, East')
    add_dx_coil('DX West')
    run_measure(dx_cop(4))
    assert_in_delta(4.0, named(:getCoilCoolingDXSingleSpeeds, 'DX, East').ratedCOP, 1e-9)
    run_measure(dx_cop(4.5).merge('object_scope' => 'explicit_object_names', 'object_names_json' => '["DX, East"]'))
    assert_in_delta(4.5, named(:getCoilCoolingDXSingleSpeeds, 'DX, East').ratedCOP, 1e-9)
    assert_in_delta(4.0, named(:getCoilCoolingDXSingleSpeeds, 'DX West').ratedCOP, 1e-9)
  end

  def test_rejects_bad_modifier_arguments
    add_dx_coil('DX One')
    base = dx_cop(4)
    assert_rejected_without_changes(base.merge('modifier_arguments_json' => '[1]'), error: /JSON object/)
    assert_rejected_without_changes(base.merge('modifier_arguments_json' => '{"target_object_names":"DX One"}'),
                                    error: /target_object_names/)
    assert_rejected_without_changes(
      base.merge('modifier_arguments_json' => '{"efficiency_metric":"dx_cooling_cop","bogus":1}'), error: /bogus/
    )
    assert_rejected_without_changes(
      { 'modifier_measure' => 'modify_existing_hvac_equipment_efficiencies', 'modifier_arguments_json' => '{}' },
      error: /efficiency_metric/
    )
  end

  def test_explicit_scope_keeps_modifier_checks
    add_dx_coil('DX One')
    assert_rejected_without_changes(dx_cop(4).merge('object_scope' => 'explicit_object_names', 'object_names_json' => '[]'),
                                    error: /object_names_json/)
    assert_rejected_without_changes(dx_cop(4).merge('object_scope' => 'explicit_object_names',
                                                    'object_names_json' => '["Missing Coil"]'),
                                    error: /Missing Coil/)
  end
end
