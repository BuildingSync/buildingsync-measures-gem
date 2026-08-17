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

### HVAC system type mapping

Resolve `hvac_system_type` in this order:

1. Use a recognized `HVAC/PrincipalHVACSystemType` value (L100).
2. Otherwise, infer the type from a consistent combination of detailed L200 fields. Do not infer a topology from one generic field such as `HeatingMedium` alone.
3. Use `unknown` when detailed records are incomplete, contradictory, or match more than one choice. `other` requires an explicit `Other` classification; it is not the ambiguity fallback.

The L200 column uses these path aliases, all relative to `HVAC`:

- `HS` = `HeatingAndCoolingSystems/HeatingSources/HeatingSource`
- `CS` = `HeatingAndCoolingSystems/CoolingSources/CoolingSource`
- `DL` = `HeatingAndCoolingSystems/Deliveries/Delivery`
- `HP` = `HS/HeatingSourceType/HeatPump`
- `DX` = `CS/CoolingSourceType/DX`
- `CA` = `DL/DeliveryType/CentralAirDistribution`
- `ZE` = `DL/DeliveryType/ZoneEquipment`
- `HP plant`, `CP plant`, and `CD plant` = `Plants/HeatingPlants/HeatingPlant`, `Plants/CoolingPlants/CoolingPlant`, and `Plants/CondenserPlants/CondenserPlant`, respectively.

Plant and source IDrefs must resolve within the selected `HVACSystem`: `HS/HeatingSourceType/SourceHeatingPlantID`, `HP/LinkedHeatingPlantID`, `CS/CoolingSourceType/CoolingPlantID`, `CA/ReheatPlantID`, and related source/delivery IDs are evidence only after their referenced records are resolved.

| `hvac_system_type` choice | L100 `PrincipalHVACSystemType` value | Possible L200 evidence or required combination | Reader note |
|---|---|---|---|
| `packaged_terminal_air_conditioner` | `Packaged Terminal Air Conditioner` | `DX/DXSystemType = Packaged terminal air conditioner (PTAC)` + `ZE/FanBased`; heating source may vary | Do not require heat-pump heating. |
| `packaged_terminal_heat_pump` | `Packaged Terminal Heat Pump` | `HP/HeatPumpType = Packaged Terminal` + `DX/DXSystemType = Packaged terminal heat pump (PTHP)` + `ZE/FanBased` | Require both heating and cooling evidence when both records are available. |
| `four_pipe_fan_coil_unit` | `Four Pipe Fan Coil Unit` | `ZE/FanBased` + `HS/HeatingMedium = Hot water` + `CS/CoolingMedium = Chilled water` + resolved heating and cooling plants | The two hydronic media and both plants distinguish a four-pipe fan coil from generic zone fan equipment. |
| `packaged_rooftop_air_conditioner` | `Packaged Rooftop Air Conditioner` | `DX/DXSystemType = Packaged/unitary direct expansion/RTU` + `CA`; no packaged-unitary heat-pump evidence | A generic DX source without central-air delivery is insufficient. |
| `packaged_rooftop_heat_pump` | `Packaged Rooftop Heat Pump` | `HP/HeatPumpType = Packaged Unitary` + `DX/DXSystemType = Packaged/unitary heat pump` + `CA` | Use `packaged_terminal_heat_pump` instead when terminal/zone evidence identifies a PTHP. |
| `packaged_rooftop_vav_hot_water_reheat` | `Packaged Rooftop VAV with Hot Water Reheat` | `DX/DXSystemType = Packaged/unitary direct expansion/RTU` + `CA/TerminalUnit = VAV terminal box fan powered with reheat` or `VAV terminal box not fan powered with reheat` + `CA/ReheatSource = Heating plant` + `CA/ReheatPlantID` resolving to `HP plant/Boiler/BoilerType = Hot water` | Packaged DX distinguishes this from built-up central VAV. |
| `packaged_rooftop_vav_electric_reheat` | `Packaged Rooftop VAV with Electric Reheat` | `DX/DXSystemType = Packaged/unitary direct expansion/RTU` + `CA/TerminalUnit = VAV terminal box fan powered with reheat` or `VAV terminal box not fan powered with reheat` + `CA/ReheatSource = Local electric resistance` | Do not infer electric reheat merely because the primary heat source is electric. |
| `vav_with_hot_water_reheat` | `VAV with Hot Water Reheat` | `CA/TerminalUnit = VAV terminal box fan powered with reheat` or `VAV terminal box not fan powered with reheat` + `CA/ReheatSource = Heating plant` + `CA/ReheatPlantID` resolving to `HP plant/Boiler/BoilerType = Hot water` + `CS/CoolingSourceType/CoolingPlantID` resolving to `CP plant/Chiller` | Central boiler/chiller evidence and the absence of packaged-RTU evidence distinguish this built-up type. |
| `vav_with_electric_reheat` | `VAV with Electric Reheat` | `CA/TerminalUnit = VAV terminal box fan powered with reheat` or `VAV terminal box not fan powered with reheat` + `CA/ReheatSource = Local electric resistance` + `CS/CoolingSourceType/CoolingPlantID` resolving to `CP plant/Chiller` | Local electric reheat plus a central chiller distinguishes this built-up type. |
| `warm_air_furnace` | `Warm Air Furnace` | `HS/HeatingSourceType/Furnace/FurnaceType = Warm air` + an air delivery | The furnace enum is stronger evidence than fuel or heating medium. |
| `ventilation_only` | `Ventilation Only` | `OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = Exhaust only` or `Supply only`, with no space-heating or cooling source serving the same premises | Use `unknown` if conditioning sources cannot be ruled out. |
| `dedicated_outdoor_air_system` | `Dedicated Outdoor Air System` | `OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = Dedicated outdoor air system` | This detailed enum is direct evidence; linked premises may associate separate zone-conditioning equipment. |
| `water_loop_heat_pump` | `Water Loop Heat Pump` | Heat-pump heating/cooling evidence + `CD plant/WaterCooled`; no `CD plant/GroundSource` classification | A water-cooled condenser record by itself does not prove a water-loop heat-pump system. |
| `ground_source_heat_pump` | `Ground Source Heat Pump` | Heat-pump heating/cooling evidence + `CD plant/GroundSource/GroundSourceType = Open loop ground water` or `Closed loop ground source` | Resolve plant/source relationships; do not classify every system in a building with a ground loop as ground-source. |
| `vrf_terminal_unit` | `VRF Terminal Unit` | `DX/DXSystemType = Variable refrigerant flow` + zone delivery evidence, normally `ZE/FanBased` | The VRF DX enum is the principal detailed discriminator. |
| `chilled_beam` | `Chilled Beam` | `ZE/Convection/ConvectionType = Chilled beam` + chilled-water cooling source/plant evidence | The current measure also accepts a primary-air fraction, but BuildingSync 2.7.0 has no direct field for it. |
| `radiant_system` | No exact L100 enum; do not substitute `Other` automatically | `ZE/Radiant/RadiantType = Radiator` or `Radiant floor or ceiling` + the applicable hot-water and/or chilled-water source | This is a measure extension inferred from L200 delivery detail. |
| `other` | `Other` | An explicit applicable `Other` branch/value that cannot be represented by another supported choice | The measure intentionally leaves existing HVAC unchanged. |
| `unknown` | `Unknown` | Explicit `Unknown`, absent topology, conflicting evidence, or unresolved required IDrefs | The measure intentionally leaves existing HVAC unchanged. |
| `existing_unknown_mixed_system` (legacy) | `Unknown` | Same evidence as `unknown` | Normalized to `unknown` by the measure. |
| `vav_with_boiler_and_central_chiller` (legacy) | `VAV with Hot Water Reheat` | Same evidence as `vav_with_hot_water_reheat`, with `HP plant/Boiler/BoilerType = Hot water` and `CP plant/Chiller/ChillerType` present | Normalized to `vav_with_hot_water_reheat` by the measure. |
| `fan_coil_with_central_plant` (legacy) | `Four Pipe Fan Coil Unit` | Same evidence as `four_pipe_fan_coil_unit`, with resolved heating and cooling plants | Normalized to `four_pipe_fan_coil_unit` by the measure. |
