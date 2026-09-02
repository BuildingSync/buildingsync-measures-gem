# HVAC Measure Index and Migration Guide

The monolithic `modify_hvac` measure has been split into independent measures with narrow responsibilities:

- 17 topology measures each support `operation = create` or `operation = replace` for one exact HVAC topology.
- 5 `modify_existing_*` measures change named controls, efficiencies, heat recovery, or plant properties without classifying or rebuilding HVAC.

New workflows should use these independent measures. `modify_hvac` remains in the gem temporarily for backward compatibility and is deprecated.

## Choosing an operation

1. Resolve BuildingSync IDs and linked premises to exact OpenStudio object and thermal-zone names before invoking a measure.
2. Choose one exact topology from the index below.
3. Set `operation = create` only when every target zone is unserved. A blank `target_zone_names` selects all thermal zones.
4. Set `operation = replace` when existing HVAC dedicated to named zones must be removed. Replacement requires an explicit, complete `target_zone_names` list.
5. Run focused `modify_existing_*` measures afterward for audited temperatures, efficiencies, capacities, economizers, or heat recovery.

Selection of the topology, interpretation of legacy aliases, and BuildingSync ID-to-model-name resolution belong to the consuming workflow. The measures do not dispatch from a BuildingSync enum or infer object names.

## Exact topology index

| Legacy `hvac_system_type` | Topology measure |
|---|---|
| `packaged_terminal_air_conditioner` | [`hvac_ptac`](../lib/measures/hvac_ptac/README.md) |
| `packaged_terminal_heat_pump` | [`hvac_pthp`](../lib/measures/hvac_pthp/README.md) |
| `four_pipe_fan_coil_unit` | [`hvac_four_pipe_fan_coil`](../lib/measures/hvac_four_pipe_fan_coil/README.md) |
| `packaged_rooftop_air_conditioner` | [`hvac_packaged_rooftop_ac`](../lib/measures/hvac_packaged_rooftop_ac/README.md) |
| `packaged_rooftop_heat_pump` | [`hvac_packaged_rooftop_heat_pump`](../lib/measures/hvac_packaged_rooftop_heat_pump/README.md) |
| `packaged_rooftop_vav_hot_water_reheat` | [`hvac_packaged_rooftop_vav_hw_reheat`](../lib/measures/hvac_packaged_rooftop_vav_hw_reheat/README.md) |
| `packaged_rooftop_vav_electric_reheat` | [`hvac_packaged_rooftop_vav_electric_reheat`](../lib/measures/hvac_packaged_rooftop_vav_electric_reheat/README.md) |
| `vav_with_hot_water_reheat` | [`hvac_vav_hw_reheat`](../lib/measures/hvac_vav_hw_reheat/README.md) |
| `vav_with_electric_reheat` | [`hvac_vav_electric_reheat`](../lib/measures/hvac_vav_electric_reheat/README.md) |
| `warm_air_furnace` | [`hvac_warm_air_furnace`](../lib/measures/hvac_warm_air_furnace/README.md) |
| `ventilation_only` | [`hvac_ventilation_only`](../lib/measures/hvac_ventilation_only/README.md) |
| `dedicated_outdoor_air_system` | [`hvac_doas`](../lib/measures/hvac_doas/README.md) |
| `water_loop_heat_pump` | [`hvac_water_loop_heat_pump`](../lib/measures/hvac_water_loop_heat_pump/README.md) |
| `ground_source_heat_pump` | [`hvac_ground_source_heat_pump`](../lib/measures/hvac_ground_source_heat_pump/README.md) |
| `vrf_terminal_unit` | [`hvac_vrf`](../lib/measures/hvac_vrf/README.md) |
| `chilled_beam` | [`hvac_chilled_beam`](../lib/measures/hvac_chilled_beam/README.md) |
| `radiant_system` | [`hvac_radiant`](../lib/measures/hvac_radiant/README.md) |

Each linked README contains the measure-specific BuildingSync candidate mapping, selection rules, conversions, confidence, and limitations.

## Legacy aliases and metadata-only choices

| Legacy choice | Migration |
|---|---|
| `vav_with_boiler_and_central_chiller` | Resolve upstream to `vav_with_hot_water_reheat`, then set the measure operation. |
| `fan_coil_with_central_plant` | Resolve upstream to `four_pipe_fan_coil_unit`, then set the measure operation. |
| `other` | Do not invoke a topology measure until the consumer resolves an exact supported topology. |
| `unknown` | Leave HVAC unchanged or resolve the topology upstream. |
| `existing_unknown_mixed_system` | Leave HVAC unchanged or resolve each constituent system upstream. |

The aliases are intentionally not implemented as dispatching measures.

## Focused modifiers

| Measure | Scope and invocation model |
|---|---|
| [`modify_existing_air_loop_controls`](../lib/measures/modify_existing_air_loop_controls/README.md) | Exact air-loop names; optionally changes cooling/heating design supply-air temperatures and/or economizer settings. |
| [`modify_existing_hvac_equipment_efficiencies`](../lib/measures/modify_existing_hvac_equipment_efficiencies/README.md) | Exact component or equipment names; applies one selected efficiency metric and value per invocation. |
| [`modify_existing_plant_equipment`](../lib/measures/modify_existing_plant_equipment/README.md) | Exact boiler or chiller names; applies one selected capacity or efficiency property and value per invocation. |
| [`modify_existing_heat_recovery`](../lib/measures/modify_existing_heat_recovery/README.md) | Exact sensible-and-latent heat-exchanger names; applies sensible or latent effectiveness per invocation. |
| [`modify_existing_plant_loop_temperatures`](../lib/measures/modify_existing_plant_loop_temperatures/README.md) | Exact plant-loop names; sets the sizing design loop exit temperature. |

### Legacy argument migration

| Legacy `modify_hvac` argument | Independent measure migration |
|---|---|
| `hvac_system_type` | Select one exact neutral measure from the topology index. |
| `target_zone_names` | Pass to the selected topology measure after resolving BuildingSync premises. |
| `target_air_loop_name` | Use plural `target_air_loop_names` in `modify_existing_air_loop_controls`. Blank no longer means all; provide exact names. |
| `synthesize_if_missing` | Choose explicitly: `operation = create`, `operation = replace`, or a modifier for existing objects. |
| `central_cooling_supply_air_temperature_c`, `central_heating_supply_air_temperature_c` | `modify_existing_air_loop_controls` with `set_supply_air_temperatures = true`. |
| `doas_supply_air_temperature_c` | `modify_existing_air_loop_controls` on the resolved DOAS or primary-air loop. |
| `economizer_control_type`, `economizer_high_limit_dry_bulb_temperature_c`, `economizer_high_limit_enthalpy_j_kg` | `modify_existing_air_loop_controls` with `set_economizer = true`. |
| `dx_cooling_cop` | `modify_existing_hvac_equipment_efficiencies` metric `dx_cooling_cop`. |
| `gas_furnace_thermal_efficiency` | `modify_existing_hvac_equipment_efficiencies` metric `gas_burner_efficiency`. |
| `heat_pump_cooling_cop` | Select `dx_cooling_cop`, `water_to_air_cooling_cop`, or `vrf_cooling_cop` according to the exact named object type. |
| `heat_pump_heating_cop` | Select `dx_heating_cop`, `water_to_air_heating_cop`, or `vrf_heating_cop` according to the exact named object type. |
| `backup_resistance_efficiency` | `modify_existing_hvac_equipment_efficiencies` metric `electric_heating_efficiency`. |
| `boiler_capacity_kw`, `design_heating_capacity_kw` | `modify_existing_plant_equipment` property `boiler_capacity_kw`; the generic design value requires an explicitly resolved boiler target. |
| `boiler_nominal_thermal_efficiency` | `modify_existing_plant_equipment` property `boiler_thermal_efficiency`. |
| `chiller_capacity_tons`, `design_cooling_capacity_tons` | `modify_existing_plant_equipment` property `chiller_capacity_tons`; the generic design value requires an explicitly resolved chiller target. |
| `chiller_reference_cop` | `modify_existing_plant_equipment` property `chiller_reference_cop`. |
| `erv_sensible_effectiveness` | `modify_existing_heat_recovery` metric `sensible_effectiveness`. |
| `erv_latent_effectiveness` | `modify_existing_heat_recovery` metric `latent_effectiveness`. |
| `radiant_chilled_water_supply_temperature_c`, `radiant_hot_water_supply_temperature_c` | `modify_existing_plant_loop_temperatures`; invoke separately for exact cooling and heating loop names. |
| `chilled_beam_primary_air_fraction` | No model-changing replacement; retain as audit/workflow metadata if needed. |
| `year_installed`, `condition_assessment`, `control_type_audit`, `zone_control_strategy` | No model-changing replacement; retain in the BuildingSync/audit data layer. |
| `preserve_existing_sizing` | No direct argument. Capacity remains unchanged unless a capacity property is explicitly applied with `modify_existing_plant_equipment`; newly created systems use standards sizing defaults. |

## Safety and lifecycle rules

- `create` fails when a target zone already has zone HVAC or air-loop service.
- `replace` resolves all target names and rejects partial removal of shared air loops before deletion. VRF also rejects partial removal of a shared outdoor unit.
- `replace` preserves every pre-existing plant loop. This avoids deleting shared infrastructure but can leave unused plant objects after terminal removal.
- OpenStudio model edits are not transactional. A failure during synthesis can leave an in-memory model partially changed; run replacements against a disposable copy or workflow checkpoint.
- Modifiers use exact OpenStudio object names. They do not accept BuildingSync IDs, wildcards, or inferred relationships.
- Topology measures use `90.1-2013`, `90.1-2016`, or `90.1-2019`; the default is `90.1-2019`.

## Topology-specific limitations

- **Ventilation-only:** constructed directly because openstudio-standards 0.8.2 does not recognize a `Ventilation Only` key. It does not provide separate zone sensible conditioning.
- **DOAS:** constructed directly. It has outdoor-air delivery and a fan but no outdoor-air heating/cooling coils or separate zone sensible-conditioning system.
- **Chilled beam:** openstudio-standards 0.8.2 has no chilled-beam key. The measure creates supporting plants through temporary fan-coil synthesis, removes those fan coils, installs four-pipe beams, and builds the primary-air loop directly. The primary-air loop has no conditioning coils, heat recovery, or humidity controls.
- **Radiant:** requires modeled zone surfaces. Standards changes constructions and assigns internal-source radiant surfaces; BuildingSync commonly lacks enough information to map individual surfaces.
- **Plant-based systems:** new plants can be created rather than merged into existing infrastructure. Apply audited plant properties afterward with focused modifiers.

## Deprecation status

`modify_hvac` is retained temporarily so existing workflows can migrate. It should not be selected by new workflows. Removal of the legacy directory, its direct test, and its package inventory entry is a separate breaking-release step.
