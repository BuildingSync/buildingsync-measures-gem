# Semantic Mapping: modify_hvac to ASHRAE Standard 211 Level 2 Audit

## Purpose

This document maps the `modify_hvac` OpenStudio measure to the HVAC-related
information needs typically associated with an ASHRAE Standard 211 Level 2 (L2)
energy audit workflow.

This is semantic alignment, not a claim of full ASHRAE 211 compliance. The
measure is a per-type dispatcher that either modifies existing HVAC equipment
or synthesizes missing systems via `openstudio-standards`
(`Standard.build('90.1-2019').model_add_hvac_system`). It covers all 18
BuildingSync `PrincipalHVACSystemType` enums plus a `radiant_system` extension
(19 types total). Refer to
[modify_hvac_measure.md](modify_hvac_measure.md) for the full argument and
implementation reference and
[l2-hvac-audit-translation-plan.md](l2-hvac-audit-translation-plan.md) for the
architectural roadmap.

## ASHRAE 211 Reference

- ASHRAE Standard 211, Section 6.2.1.3, HVAC Systems
- ASHRAE Standard 211, Section 6.2.1.5, Central Plant
- ASHRAE Standard 211, Section 6.2.1.6, HVAC Distribution and Terminal Units
- ASHRAE Standard 211, Section 6.2.1.7, HVAC Controls

## Measure Scope

The measure supports the 18 BuildingSync `PrincipalHVACSystemType` enums plus
`radiant_system`. Each maps to an `openstudio-standards` template used when
`synthesize_if_missing = true`:

| `hvac_system_type` | Standards Template | Equipment Touched |
|---|---|---|
| `packaged_terminal_air_conditioner` | `PTAC` | `ZoneHVACPackagedTerminalAirConditioner` (DX clg + elec/gas htg) |
| `packaged_terminal_heat_pump` | `PTHP` | `ZoneHVACPackagedTerminalHeatPump` (DX clg/htg + elec backup) |
| `four_pipe_fan_coil_unit` | `Fan Coil` | `ZoneHVACFourPipeFanCoil` + boiler + chiller |
| `packaged_rooftop_air_conditioner` | `PSZ-AC` | Per-zone air loops, DX clg + gas/elec htg |
| `packaged_rooftop_heat_pump` | `PSZ-HP` | Per-zone air loops, DX clg/htg + supplemental |
| `packaged_rooftop_vav_hot_water_reheat` | `PVAV Reheat` | VAV loop + DX clg + HW reheat + boiler |
| `packaged_rooftop_vav_electric_reheat` | `PVAV PFP Boxes` | VAV loop + DX clg + parallel fan-powered elec reheat |
| `vav_with_hot_water_reheat` | `VAV Reheat` | Built-up VAV + HW reheat + boiler + chiller |
| `vav_with_electric_reheat` | `VAV PFP Boxes` | Built-up VAV + elec reheat + chiller |
| `warm_air_furnace` | `Forced Air Furnace` | Air loop gas furnace or `ZoneHVACUnitHeater` |
| `ventilation_only` | `Ventilation Only` | Air loop, no conditioning |
| `dedicated_outdoor_air_system` | `DOAS` | Central DOAS loop + optional ERV |
| `water_loop_heat_pump` | `Water Source Heat Pumps` | `ZoneHVACWaterToAirHeatPump` + boiler loop |
| `ground_source_heat_pump` | `Ground Source Heat Pumps` | `ZoneHVACWaterToAirHeatPump` on ground loop |
| `vrf_terminal_unit` | `VRF` | `AirConditionerVariableRefrigerantFlow` outdoor unit |
| `chilled_beam` | `DOAS` (scaffold) | DOAS loop + boiler + chiller; beam coils metadata-only |
| `radiant_system` | `Radiant Slab` | Low-temp radiant + boiler + chiller, radiant plant supply temps |
| `other` | — | Metadata only, returns NA |
| `unknown` | — | Metadata only, returns NA |

Legacy audit aliases remap to canonical values:

- `vav_with_boiler_and_central_chiller` → `vav_with_hot_water_reheat`
- `fan_coil_with_central_plant` → `four_pipe_fan_coil_unit`
- `existing_unknown_mixed_system` → `unknown`

## Semantic Mapping

Arguments are grouped by property cluster. Each cluster maps to a distinct
subset of L2 audit findings.

### System Type Classification

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| HVAC system type classification | `hvac_system_type` choice (19 enums + aliases) | System type identification during HVAC systems review | Dispatches to the correct per-type modifier, synthesizing the system via openstudio-standards when absent. |
| Synthesize when missing | `synthesize_if_missing` (default `true`) | Audit-identified system type not represented in seed model | When true, runs `model_add_hvac_system` with the mapped template then applies cluster knobs. |
| Preserve autosized capacities | `preserve_existing_sizing` (default `false`) | Audit data-quality decision: accept nameplate sizing vs. design-day autosize | When true, skips capacity hard-sizing; only efficiencies, COPs, and control parameters are written. |

### Air-Loop Cluster (Central-Air Systems)

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| Economizer control type | `economizer_control_type` (FixedDryBulb / DifferentialDryBulb / FixedEnthalpy / DifferentialEnthalpy / ElectronicEnthalpy / NoEconomizer) | Economizer type from controls/sequence review | Written to `ControllerOutdoorAir` on each targeted air loop. |
| Economizer dry-bulb high limit | `economizer_high_limit_dry_bulb_temperature_c` | OA economizer lockout temperature threshold | Applies to fixed or differential dry-bulb strategies. |
| Economizer enthalpy high limit | `economizer_high_limit_enthalpy_j_kg` | OA economizer lockout enthalpy threshold | Applies to fixed, differential, or electronic enthalpy strategies. |
| Central cooling supply air temperature | `central_cooling_supply_air_temperature_c` | Design cooling SAT from controls documentation | Written to `SizingSystem` for PSZ / PVAV / VAV / Furnace loops. |
| Central heating supply air temperature | `central_heating_supply_air_temperature_c` | Design heating SAT from controls documentation | Written to `SizingSystem` for PSZ / PVAV / VAV / Furnace loops. |
| DOAS supply air temperature | `doas_supply_air_temperature_c` | Neutral-deck / DOAS discharge temperature design | Written to `SizingSystem` for DOAS, ventilation_only, and chilled-beam loops. |
| ERV sensible effectiveness | `erv_sensible_effectiveness` | Observed/rated heat recovery sensible effectiveness | Written to `HeatExchangerAirToAirSensibleAndLatent` (100% and 75% flow, heating and cooling). |
| ERV latent effectiveness | `erv_latent_effectiveness` | Observed/rated heat recovery latent effectiveness | Written to `HeatExchangerAirToAirSensibleAndLatent` (100% and 75% flow, heating and cooling). |

### Plant Cluster (Hydronic Loops)

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| Boiler capacity override | `boiler_capacity_kw` (0 = autosize) | Boiler nameplate capacity from equipment survey | Written to `BoilerHotWater#setNominalCapacity` (kW × 1000). |
| Boiler thermal efficiency | `boiler_nominal_thermal_efficiency` | Boiler rated or observed thermal efficiency | Written to all `BoilerHotWater` objects. |
| Chiller capacity override | `chiller_capacity_tons` (0 = autosize) | Chiller nameplate capacity from equipment survey | Written to `ChillerElectricEIR#setReferenceCapacity` (tons × 3516.85). |
| Chiller reference COP | `chiller_reference_cop` | Chiller rated efficiency or retrofit assumption | Written to all `ChillerElectricEIR` objects. |
| Design heating capacity fallback | `design_heating_capacity_kw` | Building-level heating load estimate | Used as boiler sizing fallback when `boiler_capacity_kw` is zero. |
| Design cooling capacity fallback | `design_cooling_capacity_tons` | Building-level cooling load estimate | Used as chiller sizing fallback when `chiller_capacity_tons` is zero. |

### DX / Heat-Pump / Furnace Cluster (Coil-Level)

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| DX cooling COP | `dx_cooling_cop` | Packaged DX cooling rated EER/COP from nameplate | Written to `CoilCoolingDXSingleSpeed#setRatedCOP` and `CoilCoolingDXTwoSpeed` high/low speed COPs. Applies to PTAC / PSZ-AC / PVAV / furnace with DX. |
| Gas furnace thermal efficiency | `gas_furnace_thermal_efficiency` | Gas burner efficiency from nameplate or combustion test | Written to `CoilHeatingGas#setGasBurnerEfficiency`. Applies to PSZ-AC / PVAV HW / Furnace. |
| Heat pump cooling COP | `heat_pump_cooling_cop` | Heat pump rated cooling COP | Written to `CoilCoolingDXSingleSpeed` or `CoilCoolingWaterToAirHeatPumpEquationFit`, plus `AirConditionerVariableRefrigerantFlow#setRatedCoolingCOP`. Applies to PTHP / PSZ-HP / VRF / WSHP / GSHP. |
| Heat pump heating COP | `heat_pump_heating_cop` | Heat pump rated heating COP | Written to `CoilHeatingDXSingleSpeed` or `CoilHeatingWaterToAirHeatPumpEquationFit`, plus `AirConditionerVariableRefrigerantFlow#setRatedHeatingCOP`. Applies to PTHP / PSZ-HP / VRF / WSHP / GSHP. |
| Backup/supplemental electric resistance efficiency | `backup_resistance_efficiency` | Supplemental resistance heater efficiency (typically 1.0) | Written to `CoilHeatingElectric#setEfficiency`. Applies to PTHP / PSZ-HP / PFP boxes / elec furnaces. |

### Radiant & Chilled-Beam Cluster

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| Radiant chilled water supply temperature | `radiant_chilled_water_supply_temperature_c` | Radiant cooling loop design supply temperature | Written to the radiant chilled-water `PlantLoop#sizingPlant.setDesignLoopExitTemperature`. |
| Radiant hot water supply temperature | `radiant_hot_water_supply_temperature_c` | Radiant heating loop design supply temperature | Written to the radiant hot-water `PlantLoop#sizingPlant.setDesignLoopExitTemperature`. |
| Chilled beam primary air fraction | `chilled_beam_primary_air_fraction` | Primary-air vs. induced-air ratio for active chilled beams | Metadata only in current scope; DOAS scaffold is built but beam coils are not parameterized. |

### Scoping and Targeting

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| Air loop scope | `target_air_loop_name` (blank = all) | Multi-system building with distinct air handling units | Selects which air loops receive air-loop cluster updates. |
| Zone scope | `target_zone_names` (comma-separated, blank = all) | Zone-level survey scope (per-floor or per-wing audits) | Zone-equipment branches (PTAC/PTHP/FCU/WSHP/GSHP/radiant/VRF terminal) filter on `thermalZone` membership. Plant-level updates always apply globally. |

### Audit Metadata (No Simulation Impact)

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| Year installed | `year_installed` stored in building description | Equipment vintage for replacement urgency | Informational; supports audit traceability. |
| Condition assessment | `condition_assessment` (excellent / good / average / poor / unknown) | Site-observed equipment condition | Informational; supports retrofit urgency and lifecycle cost context. |
| Control type | `control_type_audit` (pneumatic / direct_digital_control / unknown) | Observed control system type | Informational; simulation uses explicit OpenStudio control objects regardless. |
| Zone control strategy | `zone_control_strategy` (core_perimeter / all_zones / space_types) | Thermostat zoning strategy observed during audit | Metadata only; does not drive setpoint manager configuration. |
| Run-level reporting | Initial and final condition with counts of updated loops, boilers, chillers, and coils | Audit traceability and scope confirmation | Identifies which model objects were changed; is not a complete audit report artifact. |

## What This Measure Supports in an L2 Audit Workflow

This measure supports the HVAC analysis phase of an L2 audit for buildings
across all major BuildingSync system classifications.

It is useful for:

- Translating L2 system-type classification into a simulation-ready model,
  either by tuning existing equipment or synthesizing missing topologies via
  `openstudio-standards`
- Applying audit-observed efficiencies (boiler, chiller, DX, heat pump, gas
  furnace, electric resistance) to the correct coil and plant objects
- Hard-sizing plant capacities from audit nameplate or survey data
- Applying economizer strategy, supply air temperature, and ERV effectiveness
  updates to air loops
- Encoding audit metadata (vintage, condition, controls type, zoning strategy)
  into the model for ECM prioritization and traceability
- Running baseline-versus-proposed comparisons for efficiency and
  heat-recovery ECMs across packaged, built-up, hydronic, VRF, and radiant
  systems

## What Is Not Covered

The measure intentionally does not cover:

- Fuel-type switching beyond what openstudio-standards selects (gas/electric
  heating source is hard-coded at synthesis: `NaturalGas` primary, `Electricity`
  backup)
- Per-object targeting within the same type (for example, selecting one of
  several boilers); efficiency and capacity updates apply to all matching
  objects (zone-scoping applies only to zone equipment)
- Variable-vs-constant flow pump configuration
- Chilled-beam terminal coil parameterization (DOAS scaffold only)
- Detailed controls sequences (demand reset, enthalpy reset, static-pressure
  reset, optimum start)
- Zone setpoint manager customization beyond openstudio-standards defaults
- Full audit report generation and field documentation
- `other`, `unknown`, and `existing_unknown_mixed_system` — these short-circuit
  to `registerAsNotApplicable`; audit metadata is still logged to the building
  description

## Practical Interpretation for This Repository

Within this repository, `modify_hvac` is the HVAC translation layer between L2
audit findings and a simulation model.

Recommended semantic role:

- Audit input source: L2 field findings on system type, plant and coil
  efficiencies, economizer strategy, supply air temperatures, ERV performance,
  design capacities, equipment condition, and controls metadata
- Translation layer: this measure dispatches to the correct per-type modifier,
  synthesizes missing systems via openstudio-standards, then writes cluster
  knobs to the resulting objects
- Analysis output: baseline versus modified comparisons quantify ECM impact
  across packaged, built-up, hydronic, VRF, and radiant families

For buildings whose equipment type is ambiguous, set `hvac_system_type` to
`unknown` (or legacy `existing_unknown_mixed_system`) to retain existing model
topology while still recording audit metadata.

## Suggested Data Handoff from Audit to Measure

For consistent L2 workflow use, hand off at minimum:

- HVAC system type classification from audit (one of the 19 supported enums or
  a legacy alias)
- `synthesize_if_missing` decision and `preserve_existing_sizing` decision
- Air-loop cluster: economizer type and setpoints, cooling/heating SAT, DOAS
  SAT, ERV sensible/latent effectiveness
- Plant cluster: boiler efficiency and capacity, chiller COP and capacity,
  design heating/cooling capacity fallbacks
- DX/HP/furnace cluster: DX cooling COP, gas furnace efficiency, heat pump
  cooling and heating COPs, backup resistance efficiency
- Radiant/chilled-beam cluster: radiant CHW and HW supply temperatures, chilled
  beam primary air fraction
- Scoping: target air loop name, target zone names
- Metadata: year installed, condition assessment, control type, zone control
  strategy

## Conclusion

The `modify_hvac` measure translates ASHRAE 211 L2 HVAC audit findings into
OpenStudio model objects across all major BuildingSync system families. It
covers 19 system types via a per-type dispatcher backed by openstudio-standards
synthesis, and exposes four property clusters (air loop, plant, DX/HP/furnace,
radiant/chilled-beam) that map directly to L2 audit data handoffs. Areas not
covered (per-object targeting, controls sequence synthesis, full audit report
generation) are documented above and follow the strategy defined in
[l2-hvac-audit-translation-plan.md](l2-hvac-audit-translation-plan.md).
