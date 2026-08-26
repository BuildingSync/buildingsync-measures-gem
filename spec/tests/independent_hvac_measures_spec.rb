# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'
require_relative '../../lib/measures/create_ptac_hvac/measure'
require_relative '../../lib/measures/replace_with_ptac_hvac/measure'
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
      CreatePtacHvac.new => %w[target_zone_names standards_template],
      ReplaceWithPtacHvac.new => %w[target_zone_names standards_template],
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
