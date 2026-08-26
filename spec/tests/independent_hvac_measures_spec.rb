# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'
require_relative '../../lib/measures/create_four_pipe_fan_coil_hvac/measure'
require_relative '../../lib/measures/create_packaged_rooftop_ac_hvac/measure'
require_relative '../../lib/measures/create_packaged_rooftop_heat_pump_hvac/measure'
require_relative '../../lib/measures/create_ptac_hvac/measure'
require_relative '../../lib/measures/create_pthp_hvac/measure'
require_relative '../../lib/measures/replace_with_four_pipe_fan_coil_hvac/measure'
require_relative '../../lib/measures/replace_with_packaged_rooftop_ac_hvac/measure'
require_relative '../../lib/measures/replace_with_packaged_rooftop_heat_pump_hvac/measure'
require_relative '../../lib/measures/replace_with_ptac_hvac/measure'
require_relative '../../lib/measures/replace_with_pthp_hvac/measure'
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

  it 'exposes the intended focused argument contracts' do
    model = OpenStudio::Model::Model.new
    contracts = {
      CreateFourPipeFanCoilHvac.new => %w[target_zone_names standards_template],
      CreatePackagedRooftopAcHvac.new => %w[target_zone_names standards_template],
      CreatePackagedRooftopHeatPumpHvac.new => %w[target_zone_names standards_template],
      CreatePtacHvac.new => %w[target_zone_names standards_template],
      CreatePthpHvac.new => %w[target_zone_names standards_template],
      ReplaceWithFourPipeFanCoilHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPackagedRooftopAcHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPackagedRooftopHeatPumpHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPtacHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPthpHvac.new => %w[target_zone_names standards_template],
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
