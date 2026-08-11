# Modify HVAC

## Purpose

Modify existing HVAC equipment—or synthesize a missing system—from BuildingSync HVAC audit data, then apply capacities, efficiencies, air-side controls, heat recovery, and audit metadata.

## Summary

- Choose one `hvac_system_type`; `synthesize_if_missing=true` uses `openstudio-standards` when matching equipment is absent.
- Blank target names apply to all matching loops/zones. Plant capacity and efficiency updates are global.
- A capacity of `0` preserves autosizing. `boiler_capacity_kw` and `chiller_capacity_tons` override the corresponding design-capacity fallbacks.
- `preserve_existing_sizing=true` prevents capacity hard-sizing but still applies efficiencies and controls.
- `other` and `unknown` leave HVAC unchanged.

## Reference

- ASHRAE 211 L2 context: [ashrae-211-l2-semantic-mapping.md](ashrae-211-l2-semantic-mapping.md)
- Supported type/default and implementation details: [modify_hvac_measure.md](modify_hvac_measure.md)
- Implementation: [../measure.rb](../measure.rb)

## Quick Use

1. Select the applicable `HVACSystem`, preferably through its `LinkedPremises` references to the target building, section, space, or thermal zone.
2. Map `PrincipalHVACSystemType` (or compatible `PrimaryHVACSystemType`) to the measure's snake_case choice.
3. Read only fields that apply to that topology; leave unsupported values at documented defaults.
4. Convert BuildingSync units before constructing the OSW arguments.

The paths below omit the XML namespace prefix and use `HVAC` for `/BuildingSync/Facilities/Facility/Systems/HVACSystems/HVACSystem`.

## BuildingSync Reader Mapping

| Argument(s) | Candidate BuildingSync XML field(s) | Selection and conversion rule | BuildingSyncReader function |
|---|---|---|---|
| `hvac_system_type` | `HVAC/PrincipalHVACSystemType`; compatibility candidate: `HVAC/PrimaryHVACSystemType` | Map the BuildingSync enum to the supported snake_case measure choice. If the type is absent or ambiguous, use `unknown` rather than synthesizing an assumed topology. | TBD |
| `target_air_loop_name` | `HVAC/@ID`; optionally an equipment identifier under the selected delivery | This is an OpenStudio targeting name, not a direct BuildingSync property. Use the reader's stable ID-to-model-name convention; blank targets all loops. | TBD |
| `target_zone_names` | `HVAC/LinkedPremises/.../ThermalZone/@IDref`, `Space/@IDref`, or `Section/@IDref` | Resolve premise IDrefs to model thermal-zone names and join them with commas. Blank targets all zones. | TBD |
| `synthesize_if_missing`, `preserve_existing_sizing` | No direct XML field | Workflow policy. Set synthesis only when the XML topology should replace missing model equipment; preserve sizing when XML capacities are absent or not trusted. | TBD |
| `economizer_control_type` | `HVAC/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/(CentralAirDistribution or ZoneEquipment)/FanBased/AirSideEconomizer/AirSideEconomizerType` | Map `Dry bulb temperature`, `Enthalpy`, or `None` to the closest OpenStudio choice. `Demand controlled ventilation`, `Nonintegrated`, `Other`, and `Unknown` require an explicit reader policy. | TBD |
| `economizer_high_limit_dry_bulb_temperature_c` | `.../(CentralAirDistribution or ZoneEquipment)/FanBased/AirSideEconomizer/EconomizerDryBulbControlPoint` | BuildingSync is °F; convert with `°C = (°F − 32) × 5/9`. Used only for dry-bulb economizer choices. | TBD |
| `economizer_high_limit_enthalpy_j_kg` | `.../(CentralAirDistribution or ZoneEquipment)/FanBased/AirSideEconomizer/EconomizerEnthalpyControlPoint` | BuildingSync is Btu/lb; convert with `J/kg = Btu/lb × 2326`. Used only for enthalpy choices. | TBD |
| `central_cooling_supply_air_temperature_c`, `central_heating_supply_air_temperature_c`, `doas_supply_air_temperature_c` | `.../DeliveryType/(CentralAirDistribution or ZoneEquipment)/FanBased/CoolingSupplyAirTemperature` and `HeatingSupplyAirTemperature` | Convert °F to °C. Use the cooling/heating values for central-air systems. A DOAS neutral-air value may require a workflow rule or external design assumption when no dedicated value exists. | TBD |
| `erv_sensible_effectiveness`, `erv_latent_effectiveness` | `/BuildingSync/Facilities/Facility/Systems/HeatRecoverySystems/HeatRecoverySystem/HeatRecoveryEfficiency` and/or `EnergyRecoveryEfficiency`, selected through shared `LinkedPremises` | BuildingSync values are percentages; divide by `100`. `HeatRecoveryEfficiency` is a sensible candidate and `EnergyRecoveryEfficiency` is a total-energy candidate—not a direct latent effectiveness—so document any derivation. | TBD |
| `design_heating_capacity_kw`, `design_cooling_capacity_tons` | `HVAC/HeatingAndCoolingSystems/HeatingSources/HeatingSource/Capacity` and `.../CoolingSources/CoolingSource/Capacity`, with `CapacityUnits` | Convert heating capacity to kW and cooling capacity to refrigeration tons. These are fallbacks; explicit boiler/chiller capacities below take priority. | TBD |
| `boiler_capacity_kw`, `boiler_nominal_thermal_efficiency` | `HVAC/Plants/HeatingPlants/HeatingPlant/Boiler/{Capacity,CapacityUnits,AnnualHeatingEfficiencyValue,AnnualHeatingEfficiencyUnits,CombustionEfficiency,ThermalEfficiency}` | Convert capacity to kW. Prefer `ThermalEfficiency`, then a compatible annual efficiency; normalize percentages to `0–1`. | TBD |
| `chiller_capacity_tons`, `chiller_reference_cop` | `HVAC/Plants/CoolingPlants/CoolingPlant/Chiller/{Capacity,CapacityUnits,AnnualCoolingEfficiencyValue,AnnualCoolingEfficiencyUnits}` | Convert capacity to tons. COP is direct; `EER ÷ 3.412 = COP`; `COP = 3.51685 ÷ (kW/ton)`. SEER requires an explicit approximation policy. | TBD |
| `dx_cooling_cop`, `heat_pump_cooling_cop` | `HVAC/HeatingAndCoolingSystems/CoolingSources/CoolingSource/{AnnualCoolingEfficiencyValue,AnnualCoolingEfficiencyUnits}` plus `CoolingSourceType/DX` or the linked heat-pump type | Route the value by source type. Convert COP/EER/kW-per-ton as above; do not apply one source's value to unrelated cooling equipment. | TBD |
| `gas_furnace_thermal_efficiency`, `heat_pump_heating_cop`, `backup_resistance_efficiency` | `HVAC/HeatingAndCoolingSystems/HeatingSources/HeatingSource/{AnnualHeatingEfficiencyValue,AnnualHeatingEfficiencyUnits,CombustionEfficiency,ThermalEfficiency}` and `HeatingSourceType/HeatPump/HeatPumpBackupAFUE` | Route by heating source. COP is direct; AFUE/thermal/combustion percentages become fractions. Electric resistance normally defaults to `1.0` unless an explicit source is provided. | TBD |
| `radiant_chilled_water_supply_temperature_c`, `radiant_hot_water_supply_temperature_c` | Candidates: cooling plant `ChilledWaterSupplyTemperature` and heating plant `HotWaterSetpointTemperature` for systems linked to a radiant delivery | Convert °F to °C. Use only when the linked delivery is radiant; otherwise retain defaults. | TBD |
| `chilled_beam_primary_air_fraction` | No direct BuildingSync 2.7.0 field identified | Keep the default or derive from documented primary/induced airflow data outside this reader. This argument is metadata-only in the current measure. | TBD |
| `year_installed`, `condition_assessment` | `HVAC/YearInstalled`, `HVAC/HVACSystemCondition`; equipment-level alternatives exist on heating/cooling sources and plants | Select the system-level value or document how equipment-level values are aggregated. Normalize condition to `excellent`, `good`, `average`, `poor`, or `unknown`. | TBD |
| `control_type_audit`, `zone_control_strategy` | `HVAC/HVACControlSystemTypes/HVACControlSystemType`; zone strategy may be derived from `LinkedPremises` and thermostat/zoning records | Map pneumatic/DDC values to the accepted choices. Zone strategy is metadata-only and requires a documented derivation. | TBD |
