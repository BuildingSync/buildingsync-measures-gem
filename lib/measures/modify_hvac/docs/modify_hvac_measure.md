# modify_hvac — L2 HVAC Audit Translation Measure

Per-type dispatcher that modifies or synthesizes HVAC equipment across all 18
BuildingSync `PrincipalHVACSystemType` enums plus a `radiant_system` extension
(19 types total). Applies audit efficiencies/COPs, supply-air temps, economizer
controls, ERV effectiveness, and metadata. Missing systems are synthesized via
`openstudio-standards` (`Standard.build('90.1-2019').model_add_hvac_system`).

## Supported HVAC Types

Mapped to the openstudio-standards template used when `synthesize_if_missing=true`:

| `hvac_system_type` | Standards Template | Equipment Touched |
|---|---|---|
| `packaged_terminal_air_conditioner` | `PTAC` | `ZoneHVACPackagedTerminalAirConditioner` (DX clg + elec/gas htg) |
| `packaged_terminal_heat_pump` | `PTHP` | `ZoneHVACPackagedTerminalHeatPump` (DX clg/htg + elec backup) |
| `four_pipe_fan_coil_unit` | `Fan Coil` | `ZoneHVACFourPipeFanCoil` + boiler + chiller |
| `packaged_rooftop_air_conditioner` | `PSZ-AC` | Per-zone air loops, DX clg + gas/elec htg (coils unwrapped from `AirLoopHVACUnitarySystem`) |
| `packaged_rooftop_heat_pump` | `PSZ-HP` | Per-zone air loops, DX clg/htg + supplemental |
| `packaged_rooftop_vav_hot_water_reheat` | `PVAV Reheat` | VAV loop + DX clg + HW reheat coils + boiler |
| `packaged_rooftop_vav_electric_reheat` | `PVAV PFP Boxes` | VAV loop + DX clg + parallel fan-powered elec reheat |
| `vav_with_hot_water_reheat` | `VAV Reheat` | Built-up VAV + HW reheat + boiler + chiller |
| `vav_with_electric_reheat` | `VAV PFP Boxes` | Built-up VAV + elec reheat + chiller |
| `warm_air_furnace` | `Forced Air Furnace` | Air loop w/ gas furnace, or `ZoneHVACUnitHeater` |
| `ventilation_only` | `Ventilation Only` | Air loop, no conditioning |
| `dedicated_outdoor_air_system` | `DOAS` | Central DOAS loop + optional ERV |
| `water_loop_heat_pump` | `Water Source Heat Pumps` | `ZoneHVACWaterToAirHeatPump` + boiler loop |
| `ground_source_heat_pump` | `Ground Source Heat Pumps` | `ZoneHVACWaterToAirHeatPump` on ground loop |
| `vrf_terminal_unit` | `VRF` | `AirConditionerVariableRefrigerantFlow` outdoor unit |
| `chilled_beam` | `DOAS` (scaffold) | DOAS loop + boiler + chiller; beam coils metadata-only |
| `radiant_system` | `Radiant Slab` | `ZoneHVACLowTempRadiantVarFlow/ConstFlow` + boiler + chiller, radiant plant supply temps |
| `other` | — | Metadata only, returns NA |
| `unknown` | — | Metadata only, returns NA |

Legacy aliases remap to canonical values:

- `vav_with_boiler_and_central_chiller` → `vav_with_hot_water_reheat`
- `fan_coil_with_central_plant` → `four_pipe_fan_coil_unit`
- `existing_unknown_mixed_system` → `unknown`

## Property Clusters

Arguments group into four property clusters plus scoping and metadata.

### 1. Air-Loop Cluster (central-air systems)

| Argument | Units | Default | Applies To |
|---|---|---|---|
| `economizer_control_type` | choice | `FixedDryBulb` | all air-loop types |
| `economizer_high_limit_dry_bulb_temperature_c` | °C | 24.0 | Fixed/Differential DB |
| `economizer_high_limit_enthalpy_j_kg` | J/kg | 64000 | Fixed/Diff/Electronic Enthalpy |
| `central_cooling_supply_air_temperature_c` | °C | 12.8 | PSZ / PVAV / VAV / Furnace |
| `central_heating_supply_air_temperature_c` | °C | 32.0 | PSZ / PVAV / VAV / Furnace |
| `doas_supply_air_temperature_c` | °C | 18.3 | DOAS / ventilation_only / chilled_beam |
| `erv_sensible_effectiveness` | 0–1 | 0 (skip) | DOAS / chilled_beam |
| `erv_latent_effectiveness` | 0–1 | 0 (skip) | DOAS / chilled_beam |

### 2. Plant Cluster (hydronic loops)

| Argument | Units | Default |
|---|---|---|
| `boiler_capacity_kw` | kW | 0 (autosize) |
| `boiler_nominal_thermal_efficiency` | 0–1 | 0.85 |
| `chiller_capacity_tons` | tons | 0 (autosize) |
| `chiller_reference_cop` | W/W | 5.5 |
| `design_heating_capacity_kw` | kW | 0 (fallback for boiler sizing) |
| `design_cooling_capacity_tons` | tons | 0 (fallback for chiller sizing) |

### 3. DX / Heat-Pump / Furnace Cluster (coil-level)

| Argument | Units | Default | Applies To |
|---|---|---|---|
| `dx_cooling_cop` | W/W | 3.5 | PTAC / PSZ-AC / PVAV / Furnace w/ DX |
| `gas_furnace_thermal_efficiency` | 0–1 | 0.8 | PSZ-AC / PVAV HW / Furnace |
| `heat_pump_cooling_cop` | W/W | 3.5 | PTHP / PSZ-HP / VRF / WSHP / GSHP |
| `heat_pump_heating_cop` | W/W | 3.2 | PTHP / PSZ-HP / VRF / WSHP / GSHP |
| `backup_resistance_efficiency` | 0–1 | 1.0 | PTHP / PSZ-HP / PFP boxes / furnace elec |

### 4. Radiant & Chilled-Beam Cluster

| Argument | Units | Default | Applies To |
|---|---|---|---|
| `radiant_chilled_water_supply_temperature_c` | °C | 15.6 | radiant_system |
| `radiant_hot_water_supply_temperature_c` | °C | 43.3 | radiant_system |
| `chilled_beam_primary_air_fraction` | 0–1 | 0.3 | chilled_beam (metadata only) |

### Scoping & Control

- `target_air_loop_name` — exact loop name, blank = all
- `target_zone_names` — comma-separated zone names, blank = all
- `synthesize_if_missing` (bool, default `true`) — add system via standards if absent
- `preserve_existing_sizing` (bool, default `false`) — keep autosized capacities, only apply efficiencies/COPs

### Metadata (audit bookkeeping only — no OSM effect)

- `year_installed` (int 1950–2100)
- `condition_assessment` — excellent / good / average / poor / unknown
- `control_type_audit` — pneumatic / direct_digital_control / unknown
- `zone_control_strategy` — core_perimeter / all_zones / space_types

## OpenStudio SDK Setters Used

Grouped by the object they touch.

### Sizing / Air Loop

- `AirLoopHVAC#sizingSystem.setCentralCoolingDesignSupplyAirTemperature(c_sat)`
- `AirLoopHVAC#sizingSystem.setCentralHeatingDesignSupplyAirTemperature(h_sat)`
- `ControllerOutdoorAir#setEconomizerControlType(type)`
- `ControllerOutdoorAir#setEconomizerMaximumLimitDryBulbTemperature(t_c)`
- `ControllerOutdoorAir#setEconomizerMaximumLimitEnthalpy(h_j_kg)`

### Plant Equipment

- `BoilerHotWater#setNominalThermalEfficiency(eff)`
- `BoilerHotWater#setNominalCapacity(cap_w)` *(cap_kw × 1000)*
- `ChillerElectricEIR#setReferenceCOP(cop)`
- `ChillerElectricEIR#setReferenceCapacity(cap_w)` *(tons × 3516.85284)*
- `PlantLoop#sizingPlant.setDesignLoopExitTemperature(t_c)` *(radiant only)*

### DX / Gas / Electric Coils

- `CoilCoolingDXSingleSpeed#setRatedCOP(cop)`
- `CoilCoolingDXTwoSpeed#setRatedHighSpeedCOP(cop)` / `setRatedLowSpeedCOP(cop)`
- `CoilHeatingDXSingleSpeed#setRatedCOP(cop)`
- `CoilHeatingGas#setGasBurnerEfficiency(eff)`
- `CoilHeatingElectric#setEfficiency(eff)`

### Water-to-Air HP Coils

- `CoilCoolingWaterToAirHeatPumpEquationFit#setRatedCoolingCoefficientofPerformance(cop)`
- `CoilHeatingWaterToAirHeatPumpEquationFit#setRatedHeatingCoefficientofPerformance(cop)`

### VRF

- `AirConditionerVariableRefrigerantFlow#setRatedCoolingCOP(cop)`
- `AirConditionerVariableRefrigerantFlow#setRatedHeatingCOP(cop)`

### ERV — `HeatExchangerAirToAirSensibleAndLatent`

- `setSensibleEffectivenessat100CoolingAirFlow(eff)` / `…at75CoolingAirFlow`
- `setSensibleEffectivenessat100HeatingAirFlow(eff)` / `…at75HeatingAirFlow`
- `setLatentEffectivenessat100CoolingAirFlow(eff)` / `…at75CoolingAirFlow`
- `setLatentEffectivenessat100HeatingAirFlow(eff)` / `…at75HeatingAirFlow`

## Implementation Notes

- **Unitary-wrapper traversal.** `AirLoopHVAC#supplyComponents` returns only the
  top-level component list. When openstudio-standards builds PSZ-AC / PSZ-HP /
  PVAV / Forced-Air Furnace, coils are wrapped inside
  `AirLoopHVACUnitarySystem` (or `AirLoopHVACUnitaryHeatPumpAirToAir`). The
  `each_supply_coil` lambda unwraps both and yields the nested
  cooling / heating / supplemental coils so the DX / gas / elec setters fire.
- **Synthesize then tune.** When no matching equipment exists, the measure calls
  `Standard.build('90.1-2019').model_add_hvac_system(model, template, 'NaturalGas', nil, 'Electricity', zones)`
  and re-queries the model, then applies the cluster knobs.
- **Zone-scoped equipment.** Zone-equipment branches skip objects whose
  `thermalZone` is not in `target_zone_names`. Plant-level updates always apply globally.
- **Legacy aliases** are remapped at the top of `run` before dispatch.
- **`other` / `unknown` / `existing_unknown_mixed_system`** short-circuit to
  `registerAsNotApplicable` — metadata is logged, no SDK calls fire.
