# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'
require_relative '../../lib/measures/create_four_pipe_fan_coil_hvac/measure'
require_relative '../../lib/measures/create_ground_source_heat_pump_hvac/measure'
require_relative '../../lib/measures/create_packaged_rooftop_ac_hvac/measure'
require_relative '../../lib/measures/create_packaged_rooftop_heat_pump_hvac/measure'
require_relative '../../lib/measures/create_packaged_rooftop_vav_electric_reheat_hvac/measure'
require_relative '../../lib/measures/create_packaged_rooftop_vav_hw_reheat_hvac/measure'
require_relative '../../lib/measures/create_ptac_hvac/measure'
require_relative '../../lib/measures/create_doas_hvac/measure'
require_relative '../../lib/measures/create_pthp_hvac/measure'
require_relative '../../lib/measures/create_ventilation_only_hvac/measure'
require_relative '../../lib/measures/create_vav_electric_reheat_hvac/measure'
require_relative '../../lib/measures/create_vav_hw_reheat_hvac/measure'
require_relative '../../lib/measures/create_water_loop_heat_pump_hvac/measure'
require_relative '../../lib/measures/create_warm_air_furnace_hvac/measure'
require_relative '../../lib/measures/create_vrf_hvac/measure'
require_relative '../../lib/measures/replace_with_four_pipe_fan_coil_hvac/measure'
require_relative '../../lib/measures/replace_with_ground_source_heat_pump_hvac/measure'
require_relative '../../lib/measures/replace_with_packaged_rooftop_ac_hvac/measure'
require_relative '../../lib/measures/replace_with_packaged_rooftop_heat_pump_hvac/measure'
require_relative '../../lib/measures/replace_with_packaged_rooftop_vav_electric_reheat_hvac/measure'
require_relative '../../lib/measures/replace_with_packaged_rooftop_vav_hw_reheat_hvac/measure'
require_relative '../../lib/measures/replace_with_ptac_hvac/measure'
require_relative '../../lib/measures/replace_with_pthp_hvac/measure'
require_relative '../../lib/measures/replace_with_doas_hvac/measure'
require_relative '../../lib/measures/replace_with_ventilation_only_hvac/measure'
require_relative '../../lib/measures/replace_with_vav_electric_reheat_hvac/measure'
require_relative '../../lib/measures/replace_with_vav_hw_reheat_hvac/measure'
require_relative '../../lib/measures/replace_with_water_loop_heat_pump_hvac/measure'
require_relative '../../lib/measures/replace_with_warm_air_furnace_hvac/measure'
require_relative '../../lib/measures/replace_with_vrf_hvac/measure'
require_relative '../../lib/measures/modify_existing_air_loop_controls/measure'
require_relative '../../lib/measures/modify_existing_hvac_equipment_efficiencies/measure'
require_relative '../../lib/measures/modify_existing_plant_equipment/measure'
require_relative '../../lib/measures/modify_existing_heat_recovery/measure'
require_relative '../../lib/measures/modify_existing_plant_loop_temperatures/measure'

RSpec.describe 'Independent HVAC measures' do
  def run_measure(measure, model, values)
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(measure.arguments(model))
    argument_map.each do |name, argument|
      next unless values.key?(name)

      updated_argument = argument.clone
      expect(updated_argument.setValue(values[name])).to be true
      argument_map[name] = updated_argument
    end
    measure.run(model, runner, argument_map)
    runner.result
  end

  def named_zone_model(zone_name = 'Target Zone')
    model = OpenStudio::Model::Model.new
    zone = OpenStudio::Model::ThermalZone.new(model)
    zone.setName(zone_name)
    space = OpenStudio::Model::Space.new(model)
    space.setName("#{zone_name} Space")
    space.setThermalZone(zone)
    [model, zone]
  end

  def named_multizone_model(prefix)
    model = OpenStudio::Model::Model.new
    zones = %w[One Two].map do |suffix|
      zone = OpenStudio::Model::ThermalZone.new(model)
      zone.setName("#{prefix} Zone #{suffix}")
      space = OpenStudio::Model::Space.new(model)
      space.setName("#{prefix} Space #{suffix}")
      space.setThermalZone(zone)
      zone
    end
    [model, zones]
  end

  it 'exposes the intended focused argument contracts' do
    model = OpenStudio::Model::Model.new
    contracts = {
      CreateDoasHvac.new => %w[target_zone_names standards_template],
      CreateFourPipeFanCoilHvac.new => %w[target_zone_names standards_template],
      CreateGroundSourceHeatPumpHvac.new => %w[target_zone_names standards_template],
      CreatePackagedRooftopAcHvac.new => %w[target_zone_names standards_template],
      CreatePackagedRooftopHeatPumpHvac.new => %w[target_zone_names standards_template],
      CreatePackagedRooftopVavElectricReheatHvac.new => %w[target_zone_names standards_template],
      CreatePackagedRooftopVavHwReheatHvac.new => %w[target_zone_names standards_template],
      CreatePtacHvac.new => %w[target_zone_names standards_template],
      CreatePthpHvac.new => %w[target_zone_names standards_template],
      CreateVentilationOnlyHvac.new => %w[target_zone_names standards_template],
      CreateVavElectricReheatHvac.new => %w[target_zone_names standards_template],
      CreateVavHwReheatHvac.new => %w[target_zone_names standards_template],
      CreateWaterLoopHeatPumpHvac.new => %w[target_zone_names standards_template],
      CreateWarmAirFurnaceHvac.new => %w[target_zone_names standards_template],
      CreateVrfHvac.new => %w[target_zone_names standards_template],
      ReplaceWithFourPipeFanCoilHvac.new => %w[target_zone_names standards_template],
      ReplaceWithGroundSourceHeatPumpHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPackagedRooftopAcHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPackagedRooftopHeatPumpHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPackagedRooftopVavElectricReheatHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPackagedRooftopVavHwReheatHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPtacHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPthpHvac.new => %w[target_zone_names standards_template],
      ReplaceWithDoasHvac.new => %w[target_zone_names standards_template],
      ReplaceWithVentilationOnlyHvac.new => %w[target_zone_names standards_template],
      ReplaceWithVavElectricReheatHvac.new => %w[target_zone_names standards_template],
      ReplaceWithVavHwReheatHvac.new => %w[target_zone_names standards_template],
      ReplaceWithWaterLoopHeatPumpHvac.new => %w[target_zone_names standards_template],
      ReplaceWithWarmAirFurnaceHvac.new => %w[target_zone_names standards_template],
      ReplaceWithVrfHvac.new => %w[target_zone_names standards_template],
      ModifyExistingAirLoopControls.new => %w[target_air_loop_names set_supply_air_temperatures cooling_supply_air_temperature_c heating_supply_air_temperature_c set_economizer economizer_control_type economizer_high_limit_dry_bulb_temperature_c economizer_high_limit_enthalpy_j_kg],
      ModifyExistingHvacEquipmentEfficiencies.new => %w[target_object_names efficiency_metric efficiency_value],
      ModifyExistingPlantEquipment.new => %w[target_plant_equipment_names property value],
      ModifyExistingHeatRecovery.new => %w[target_heat_exchanger_names effectiveness_metric effectiveness],
      ModifyExistingPlantLoopTemperatures.new => %w[target_plant_loop_names design_loop_exit_temperature_c]
    }

    contracts.each do |measure, expected_names|
      expect(measure.arguments(model).map(&:name)).to eq(expected_names)
    end
  end

  it 'creates a PTAC in an unserved target zone' do
    model, zone = named_zone_model
    result = run_measure(
      CreatePtacHvac.new,
      model,
      'target_zone_names' => zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(result.value.valueName).to eq('Success')
    expect(model.getZoneHVACPackagedTerminalAirConditioners.size).to eq(1)
    expect(zone.equipment.any? { |equipment| equipment.to_ZoneHVACPackagedTerminalAirConditioner.is_initialized }).to be true
  end

  it 'replaces existing zone equipment with a PTAC' do
    model, zone = named_zone_model
    baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
    baseboard.addToThermalZone(zone)

    result = run_measure(
      ReplaceWithPtacHvac.new,
      model,
      'target_zone_names' => zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(result.value.valueName).to eq('Success')
    expect(model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(model.getZoneHVACPackagedTerminalAirConditioners.size).to eq(1)
  end

  it 'creates a PTHP in an unserved target zone' do
    model, zone = named_zone_model

    result = run_measure(
      CreatePthpHvac.new,
      model,
      'target_zone_names' => zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(result.value.valueName).to eq('Success')
    expect(model.getZoneHVACPackagedTerminalHeatPumps.size).to eq(1)
    expect(zone.equipment.any? { |equipment| equipment.to_ZoneHVACPackagedTerminalHeatPump.is_initialized }).to be true
  end

  it 'replaces existing zone equipment with a PTHP' do
    model, zone = named_zone_model
    baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
    baseboard.addToThermalZone(zone)

    result = run_measure(
      ReplaceWithPthpHvac.new,
      model,
      'target_zone_names' => zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(result.value.valueName).to eq('Success')
    expect(model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(model.getZoneHVACPackagedTerminalHeatPumps.size).to eq(1)
  end

  it 'creates four-pipe fan coils and required plant loops' do
    model, zone = named_zone_model

    result = run_measure(
      CreateFourPipeFanCoilHvac.new,
      model,
      'target_zone_names' => zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(result.value.valueName).to eq('Success')
    expect(model.getZoneHVACFourPipeFanCoils.size).to eq(1)
    expect(model.getPlantLoops.size).to be >= 2
  end

  it 'replaces zone equipment with a fan coil and preserves existing plants' do
    model, zone = named_zone_model
    baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
    baseboard.addToThermalZone(zone)
    existing_plant = OpenStudio::Model::PlantLoop.new(model)
    existing_plant.setName('Preserved Existing Plant')
    existing_plant_handle = existing_plant.handle.to_s

    result = run_measure(
      ReplaceWithFourPipeFanCoilHvac.new,
      model,
      'target_zone_names' => zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(result.value.valueName).to eq('Success')
    expect(model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(model.getZoneHVACFourPipeFanCoils.size).to eq(1)
    expect(model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }).to include(existing_plant_handle)
  end

  it 'creates packaged rooftop AC and heat-pump air loops' do
    ac_model, ac_zone = named_zone_model('PSZ AC Zone')
    hp_model, hp_zone = named_zone_model('PSZ HP Zone')

    ac_result = run_measure(
      CreatePackagedRooftopAcHvac.new,
      ac_model,
      'target_zone_names' => ac_zone.nameString,
      'standards_template' => '90.1-2019'
    )
    hp_result = run_measure(
      CreatePackagedRooftopHeatPumpHvac.new,
      hp_model,
      'target_zone_names' => hp_zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(ac_result.value.valueName).to eq('Success')
    expect(ac_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(ac_zone)
    expect(hp_result.value.valueName).to eq('Success')
    expect(hp_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(hp_zone)
  end

  it 'replaces zone equipment with packaged rooftop AC and heat-pump loops' do
    ac_model, ac_zone = named_zone_model('Replacement AC Zone')
    hp_model, hp_zone = named_zone_model('Replacement HP Zone')
    OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(ac_model).addToThermalZone(ac_zone)
    OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(hp_model).addToThermalZone(hp_zone)

    ac_result = run_measure(
      ReplaceWithPackagedRooftopAcHvac.new,
      ac_model,
      'target_zone_names' => ac_zone.nameString,
      'standards_template' => '90.1-2019'
    )
    hp_result = run_measure(
      ReplaceWithPackagedRooftopHeatPumpHvac.new,
      hp_model,
      'target_zone_names' => hp_zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(ac_result.value.valueName).to eq('Success')
    expect(ac_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(ac_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(ac_zone)
    expect(hp_result.value.valueName).to eq('Success')
    expect(hp_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(hp_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(hp_zone)
  end

  it 'rejects partial replacement of a shared air loop before removal' do
    model, target_zone = named_zone_model('Selected Shared Zone')
    other_zone = OpenStudio::Model::ThermalZone.new(model)
    other_zone.setName('Unselected Shared Zone')
    other_space = OpenStudio::Model::Space.new(model)
    other_space.setThermalZone(other_zone)
    shared_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    shared_loop.setName('Shared Existing Loop')
    shared_loop.addBranchForZone(target_zone)
    shared_loop.addBranchForZone(other_zone)
    shared_loop_handle = shared_loop.handle.to_s

    result = run_measure(
      ReplaceWithPackagedRooftopAcHvac.new,
      model,
      'target_zone_names' => target_zone.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(result.value.valueName).to eq('Fail')
    expect(model.getAirLoopHVACs.map { |air_loop| air_loop.handle.to_s }).to include(shared_loop_handle)
    expect(shared_loop.thermalZones).to include(target_zone, other_zone)
  end

  it 'creates packaged VAV hot-water and electric-reheat systems' do
    hw_model, hw_zones = named_multizone_model('PVAV HW')
    electric_model, electric_zones = named_multizone_model('PVAV Electric')

    hw_result = run_measure(
      CreatePackagedRooftopVavHwReheatHvac.new,
      hw_model,
      'target_zone_names' => hw_zones.map(&:nameString).join(', '),
      'standards_template' => '90.1-2019'
    )
    electric_result = run_measure(
      CreatePackagedRooftopVavElectricReheatHvac.new,
      electric_model,
      'target_zone_names' => electric_zones.map(&:nameString).join(', '),
      'standards_template' => '90.1-2019'
    )

    expect(hw_result.value.valueName).to eq('Success')
    expect(hw_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*hw_zones)
    expect(hw_model.getPlantLoops).not_to be_empty
    expect(electric_result.value.valueName).to eq('Success')
    expect(electric_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*electric_zones)
  end

  it 'replaces zone equipment with packaged VAV systems and preserves existing plants' do
    hw_model, hw_zones = named_multizone_model('Replacement PVAV HW')
    electric_model, electric_zones = named_multizone_model('Replacement PVAV Electric')
    (hw_zones + electric_zones).each do |zone|
      OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(zone.model).addToThermalZone(zone)
    end
    preserved_plant = OpenStudio::Model::PlantLoop.new(hw_model)
    preserved_handle = preserved_plant.handle.to_s

    hw_result = run_measure(
      ReplaceWithPackagedRooftopVavHwReheatHvac.new,
      hw_model,
      'target_zone_names' => hw_zones.map(&:nameString).join(', '),
      'standards_template' => '90.1-2019'
    )
    electric_result = run_measure(
      ReplaceWithPackagedRooftopVavElectricReheatHvac.new,
      electric_model,
      'target_zone_names' => electric_zones.map(&:nameString).join(', '),
      'standards_template' => '90.1-2019'
    )

    expect(hw_result.value.valueName).to eq('Success')
    expect(hw_model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }).to include(preserved_handle)
    expect(hw_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*hw_zones)
    expect(electric_result.value.valueName).to eq('Success')
    expect(electric_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*electric_zones)
  end

  it 'creates and replaces built-up VAV systems' do
    hw_model, hw_zones = named_multizone_model('Built-up VAV HW')
    electric_model, electric_zones = named_multizone_model('Built-up VAV Electric')
    replacement_model, replacement_zones = named_multizone_model('Replacement Built-up VAV')
    replacement_zones.each do |zone|
      OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(replacement_model).addToThermalZone(zone)
    end

    hw_result = run_measure(CreateVavHwReheatHvac.new, hw_model,
                            'target_zone_names' => hw_zones.map(&:nameString).join(', '), 'standards_template' => '90.1-2019')
    electric_result = run_measure(CreateVavElectricReheatHvac.new, electric_model,
                                  'target_zone_names' => electric_zones.map(&:nameString).join(', '), 'standards_template' => '90.1-2019')
    replacement_result = run_measure(ReplaceWithVavHwReheatHvac.new, replacement_model,
                                     'target_zone_names' => replacement_zones.map(&:nameString).join(', '), 'standards_template' => '90.1-2019')

    expect(hw_result.value.valueName).to eq('Success')
    expect(hw_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*hw_zones)
    expect(electric_result.value.valueName).to eq('Success')
    expect(electric_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*electric_zones)
    expect(replacement_result.value.valueName).to eq('Success')
    expect(replacement_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(replacement_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*replacement_zones)
  end

  it 'creates and replaces ventilation-only and DOAS systems' do
    ventilation_model, ventilation_zones = named_multizone_model('Ventilation')
    doas_model, doas_zones = named_multizone_model('DOAS')
    replacement_model, replacement_zones = named_multizone_model('Replacement DOAS')
    ventilation_replacement_model, ventilation_replacement_zones = named_multizone_model('Replacement Ventilation')
    replacement_zones.each do |zone|
      OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(replacement_model).addToThermalZone(zone)
    end
    ventilation_replacement_zones.each do |zone|
      OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(ventilation_replacement_model).addToThermalZone(zone)
    end

    ventilation_result = run_measure(CreateVentilationOnlyHvac.new, ventilation_model,
                                     'target_zone_names' => ventilation_zones.map(&:nameString).join(', '), 'standards_template' => '90.1-2019')
    doas_result = run_measure(CreateDoasHvac.new, doas_model,
                              'target_zone_names' => doas_zones.map(&:nameString).join(', '), 'standards_template' => '90.1-2019')
    replacement_result = run_measure(ReplaceWithDoasHvac.new, replacement_model,
                                     'target_zone_names' => replacement_zones.map(&:nameString).join(', '), 'standards_template' => '90.1-2019')
    ventilation_replacement_result = run_measure(
      ReplaceWithVentilationOnlyHvac.new,
      ventilation_replacement_model,
      'target_zone_names' => ventilation_replacement_zones.map(&:nameString).join(', '),
      'standards_template' => '90.1-2019'
    )

    expect(ventilation_result.value.valueName).to eq('Success')
    expect(ventilation_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*ventilation_zones)
    expect(doas_result.value.valueName).to eq('Success'), doas_result.errors.map(&:logMessage).join('; ')
    expect(doas_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*doas_zones)
    expect(replacement_result.value.valueName).to eq('Success')
    expect(replacement_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(replacement_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*replacement_zones)
    expect(ventilation_replacement_result.value.valueName).to eq('Success')
    expect(ventilation_replacement_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(ventilation_replacement_model.getAirLoopHVACs.flat_map(&:thermalZones)).to include(*ventilation_replacement_zones)
  end

  it 'creates and replaces water-loop and ground-source heat-pump systems' do
    water_model, water_zone = named_zone_model('Water Loop HP Zone')
    ground_model, ground_zone = named_zone_model('Ground Source HP Zone')
    water_replacement_model, water_replacement_zone = named_zone_model('Replacement Water Loop HP Zone')
    ground_replacement_model, ground_replacement_zone = named_zone_model('Replacement Ground Source HP Zone')
    OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(water_replacement_model).addToThermalZone(water_replacement_zone)
    OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(ground_replacement_model).addToThermalZone(ground_replacement_zone)

    water_result = run_measure(CreateWaterLoopHeatPumpHvac.new, water_model,
                               'target_zone_names' => water_zone.nameString, 'standards_template' => '90.1-2019')
    ground_result = run_measure(CreateGroundSourceHeatPumpHvac.new, ground_model,
                                'target_zone_names' => ground_zone.nameString, 'standards_template' => '90.1-2019')
    water_replacement_result = run_measure(ReplaceWithWaterLoopHeatPumpHvac.new, water_replacement_model,
                                           'target_zone_names' => water_replacement_zone.nameString, 'standards_template' => '90.1-2019')
    ground_replacement_result = run_measure(ReplaceWithGroundSourceHeatPumpHvac.new, ground_replacement_model,
                                            'target_zone_names' => ground_replacement_zone.nameString, 'standards_template' => '90.1-2019')

    [water_result, ground_result, water_replacement_result, ground_replacement_result].each do |result|
      expect(result.value.valueName).to eq('Success'), result.errors.map(&:logMessage).join('; ')
    end
    expect(water_model.getZoneHVACWaterToAirHeatPumps.size).to eq(1)
    expect(ground_model.getZoneHVACWaterToAirHeatPumps.size).to eq(1)
    expect(water_replacement_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(ground_replacement_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
  end

  it 'creates and replaces warm-air furnace and VRF systems' do
    furnace_model, furnace_zone = named_zone_model('Furnace Zone')
    vrf_model, vrf_zones = named_multizone_model('VRF')
    furnace_replacement_model, furnace_replacement_zone = named_zone_model('Replacement Furnace Zone')
    vrf_replacement_model, vrf_replacement_zones = named_multizone_model('Replacement VRF')
    OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(furnace_replacement_model).addToThermalZone(furnace_replacement_zone)
    vrf_replacement_zones.each do |zone|
      OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(vrf_replacement_model).addToThermalZone(zone)
    end

    furnace_result = run_measure(CreateWarmAirFurnaceHvac.new, furnace_model,
                                 'target_zone_names' => furnace_zone.nameString, 'standards_template' => '90.1-2019')
    vrf_result = run_measure(CreateVrfHvac.new, vrf_model,
                             'target_zone_names' => vrf_zones.map(&:nameString).join(', '), 'standards_template' => '90.1-2019')
    furnace_replacement_result = run_measure(ReplaceWithWarmAirFurnaceHvac.new, furnace_replacement_model,
                                             'target_zone_names' => furnace_replacement_zone.nameString, 'standards_template' => '90.1-2019')
    vrf_replacement_result = run_measure(ReplaceWithVrfHvac.new, vrf_replacement_model,
                                         'target_zone_names' => vrf_replacement_zones.map(&:nameString).join(', '),
                                         'standards_template' => '90.1-2019')

    [furnace_result, vrf_result, furnace_replacement_result, vrf_replacement_result].each do |result|
      expect(result.value.valueName).to eq('Success'), result.errors.map(&:logMessage).join('; ')
    end
    expect(furnace_model.getAirLoopHVACs.flat_map(&:thermalZones) +
           furnace_model.getZoneHVACUnitHeaters.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized }).to include(furnace_zone)
    expect(vrf_model.getAirConditionerVariableRefrigerantFlows.flat_map(&:terminals).filter_map do |terminal|
      terminal.thermalZone.get if terminal.thermalZone.is_initialized
    end).to include(*vrf_zones)
    expect(furnace_replacement_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
    expect(vrf_replacement_model.getZoneHVACBaseboardConvectiveElectrics).to be_empty
  end

  it 'rejects partial replacement of a shared VRF outdoor unit before removal' do
    model, zones = named_multizone_model('Shared VRF')
    vrf = OpenStudio::Model::AirConditionerVariableRefrigerantFlow.new(model)
    terminals = zones.map do |zone|
      terminal = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model)
      terminal.addToThermalZone(zone)
      vrf.addTerminal(terminal)
      terminal
    end
    vrf_handle = vrf.handle.to_s
    terminal_handles = terminals.map { |terminal| terminal.handle.to_s }

    result = run_measure(
      ReplaceWithVrfHvac.new,
      model,
      'target_zone_names' => zones.first.nameString,
      'standards_template' => '90.1-2019'
    )

    expect(result.value.valueName).to eq('Fail')
    expect(model.getAirConditionerVariableRefrigerantFlows.map { |unit| unit.handle.to_s }).to include(vrf_handle)
    expect(model.getZoneHVACTerminalUnitVariableRefrigerantFlows.map { |terminal| terminal.handle.to_s }).to include(*terminal_handles)
  end

  it 'updates only a named air loop design temperature' do
    model = OpenStudio::Model::Model.new
    loop = OpenStudio::Model::AirLoopHVAC.new(model)
    loop.setName('Audit Air Loop')

    result = run_measure(
      ModifyExistingAirLoopControls.new,
      model,
      'target_air_loop_names' => loop.nameString,
      'set_supply_air_temperatures' => true,
      'cooling_supply_air_temperature_c' => 12.5,
      'heating_supply_air_temperature_c' => 31.0,
      'set_economizer' => false
    )

    expect(result.value.valueName).to eq('Success')
    expect(loop.sizingSystem.centralCoolingDesignSupplyAirTemperature).to be_within(0.001).of(12.5)
    expect(loop.sizingSystem.centralHeatingDesignSupplyAirTemperature).to be_within(0.001).of(31.0)
  end

  it 'updates a named electric heating coil efficiency' do
    model = OpenStudio::Model::Model.new
    coil = OpenStudio::Model::CoilHeatingElectric.new(model)
    coil.setName('Audit Electric Coil')

    result = run_measure(
      ModifyExistingHvacEquipmentEfficiencies.new,
      model,
      'target_object_names' => coil.nameString,
      'efficiency_metric' => 'electric_heating_efficiency',
      'efficiency_value' => 0.98
    )

    expect(result.value.valueName).to eq('Success')
    expect(coil.efficiency).to be_within(0.001).of(0.98)
  end

  it 'updates named plant equipment and loop properties' do
    model = OpenStudio::Model::Model.new
    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName('Audit Boiler')
    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName('Audit Heating Loop')

    equipment_result = run_measure(
      ModifyExistingPlantEquipment.new,
      model,
      'target_plant_equipment_names' => boiler.nameString,
      'property' => 'boiler_thermal_efficiency',
      'value' => 0.91
    )
    temperature_result = run_measure(
      ModifyExistingPlantLoopTemperatures.new,
      model,
      'target_plant_loop_names' => plant_loop.nameString,
      'design_loop_exit_temperature_c' => 55.0
    )

    expect(equipment_result.value.valueName).to eq('Success')
    expect(boiler.nominalThermalEfficiency).to be_within(0.001).of(0.91)
    expect(temperature_result.value.valueName).to eq('Success')
    expect(plant_loop.sizingPlant.designLoopExitTemperature).to be_within(0.001).of(55.0)
  end

  it 'updates named heat-recovery effectiveness' do
    model = OpenStudio::Model::Model.new
    exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(model)
    exchanger.setName('Audit ERV')

    result = run_measure(
      ModifyExistingHeatRecovery.new,
      model,
      'target_heat_exchanger_names' => exchanger.nameString,
      'effectiveness_metric' => 'sensible_effectiveness',
      'effectiveness' => 0.77
    )

    expect(result.value.valueName).to eq('Success')
    expect(exchanger.sensibleEffectivenessat100HeatingAirFlow).to be_within(0.001).of(0.77)
    expect(exchanger.sensibleEffectivenessat75CoolingAirFlow).to be_within(0.001).of(0.77)
  end
end
