# HVAC Measure Index and Migration Guide

The monolithic `modify_hvac` measure has been split into independent measures with narrow responsibilities:

- 17 topology measures each support `operation = create` or `operation = replace` for one exact HVAC topology.
- 5 `modify_existing_*` measures change named controls, efficiencies, heat recovery, or plant properties without classifying or rebuilding HVAC.

New workflows should use these independent measures. `modify_hvac` remains in the gem temporarily for backward compatibility and is deprecated.

## Choosing an operation

1. Resolve BuildingSync IDs and linked premises to exact OpenStudio object and thermal-zone names before invoking a measure.
2. Choose one exact topology from the index below.
3. Set `operation = create` only when every target zone is unserved. A blank `target_zone_names` selects all thermal zones. Exception: DOAS/ventilation-only loops are an outdoor-air layer. `hvac_doas` and `hvac_ventilation_only` can be created on zones that have zone equipment but no air loop; run them after all other HVAC upgrades. Zone-equipment topologies (PTAC, PTHP, fan coil, WLHP, GSHP, radiant, VRF) can be created on DOAS-served zones. When a zone-equipment topology replaces equipment, it keeps the DOAS loop. When DOAS/ventilation-only replaces, it replaces only the air loops and keeps the zone equipment. Air-loop topologies still conflict with DOAS-served zones. See [DOAS layering](#doas-layering-direct-to-zone).
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
- `replace` keeps every pre-existing plant loop that still serves a load after the replacement, for example a loop shared with zones outside the target scope or a loop that openstudio-standards reuses for the new system. A pre-existing loop left without any demand-side load is removed together with its supply equipment (boilers, chillers, cooling towers, pumps). Removing a chiller can leave its condenser loop without loads, in which case that loop is removed as well. Loops that already had no loads before the replacement are not touched.
- Messages that openstudio-standards logs while building a system are forwarded to the measure result: warnings as measure warnings, errors as measure errors that fail the step. openstudio-standards returns the model even when a step failed, so its log is the only reliable error signal; the measures also verify that every target zone received equipment.
- OpenStudio model edits are not transactional. A failure during synthesis can leave an in-memory model partially changed; run replacements against a disposable copy or workflow checkpoint.
- Modifiers use exact OpenStudio object names. They do not accept BuildingSync IDs, wildcards, or inferred relationships.
- Topology measures use `90.1-2013`, `90.1-2016`, or `90.1-2019`; the default is `90.1-2019`.

## Topology-specific limitations

- **PTAC:** DX cooling with electric-resistance heating. No hot-water plant is created.
- **Packaged rooftop AC:** DX cooling with a gas furnace heating coil and electric supplemental heat. No hot-water plant is created.
- **Ventilation-only:** constructed directly because openstudio-standards 0.8.2 does not recognize a `Ventilation Only` key. It does not provide separate zone sensible conditioning.
- **DOAS:** constructed directly. It has outdoor-air delivery and a fan but no outdoor-air heating/cooling coils or separate zone sensible-conditioning system.
- **Chilled beam:** openstudio-standards 0.8.2 has no chilled-beam key. The measure creates supporting plants through temporary fan-coil synthesis, removes those fan coils, installs four-pipe beams, and builds the primary-air loop directly. The primary-air loop has hot- and chilled-water coils held at a constant 14 °C supply-air setpoint, but no heat recovery or humidity controls. Beam sizing depends on zone design outdoor-air rates; low primary-air flow can produce undersized beams.
- **Radiant:** requires modeled zone surfaces. Standards changes constructions and assigns internal-source radiant surfaces; BuildingSync commonly lacks enough information to map individual surfaces.
- **Plant-based systems:** openstudio-standards reuses a pre-existing loop only when it carries the standards default name (`Hot Water Loop`, `Chilled Water Loop`, `Heat Pump Loop`, `Ground HX Loop`, `Ambient Loop`); otherwise new plants are created next to the existing ones. Apply audited plant properties afterward with focused modifiers.

## DOAS layering (direct to zone)

`hvac_doas` and `hvac_ventilation_only` build a ventilation loop sized on `VentilationRequirement`, with one `AirTerminalSingleDuctConstantVolumeNoReheat` per zone. The other measures recognize a loop with this setup as a DOAS loop. The loop delivers outdoor air **directly to each zone**, in parallel with the zone equipment. It is not ducted to the zone units' inlets.

```text
Outdoor air -> DOAS loop (OA system + fan) -> CV NoReheat terminal -> Zone
Zone air    -> PTAC / PTHP / fan coil / WAHP / VRF terminal (OA = 0) -> Zone
```

- **Single outdoor-air source:** the DOAS loop is the only source of outdoor air for each zone it serves. When `hvac_doas` or `hvac_ventilation_only` runs, it sets the outdoor-air flows of every existing zone unit in the target zones to 0 and logs an info message. The fields set to 0 are:
  - PTAC, PTHP, water-to-air heat pump and VRF terminal: the outdoor-air flow during cooling, during heating, and when no heating or cooling is needed.
  - Four-pipe fan coil: the maximum outdoor-air flow.
  - Radiant systems and baseboards have no outdoor air, so they are unchanged.
- **Required order: run DOAS last.** Apply `hvac_doas` / `hvac_ventilation_only` after every other HVAC upgrade in the workflow. The zone-equipment measures do not change outdoor air. If one runs after the DOAS measure, its new units keep their standards-based outdoor air, and ventilation is counted twice.
- **Zone-equipment measures on DOAS-served zones:** they are still allowed, and `replace` removes zone units but keeps the DOAS loop and its terminals. Re-run the DOAS measure afterward with `operation = replace` on those zones; it rebuilds the DOAS loop and sets the new units' outdoor air to 0.
- **Load order:** the DOAS terminal is set first in each zone's cooling and heating order. The zone units handle the remaining sensible load.
- **DOAS `replace`:** removes only the air loops serving the target zones, including their outdoor-air systems. Zone equipment is kept.
- **Not supported:** air-loop topologies (packaged rooftop, VAV, furnace, chilled beam) are rejected on DOAS-served zones, because they bring their own outdoor-air system.
- **Untreated supply air:** the DOAS loop has no outdoor-air heating or cooling coils, so the zone units absorb the outdoor-air load.

## Per-measure unit tests

All 17 independent HVAC topology measures and five `modify_existing_*` HVAC modifiers contain a local Minitest entry point and a checked-in OSM fixture. The deprecated `modify_hvac` suite is not part of this test group.

Examples:

- [DOAS test entry point](../lib/measures/hvac_doas/tests/hvac_doas_test.rb) and [fixture](../lib/measures/hvac_doas/tests/test_model.osm).
- [Plant-equipment modifier tests](../lib/measures/modify_existing_plant_equipment/tests/modify_existing_plant_equipment_test.rb) and [fixture](../lib/measures/modify_existing_plant_equipment/tests/test_model.osm).
- [Radiant tests](../lib/measures/hvac_radiant/tests/hvac_radiant_test.rb), including a zone-without-surfaces error.
- [Heat-recovery tests](../lib/measures/modify_existing_heat_recovery/tests/modify_existing_heat_recovery_test.rb), including zero effectiveness and re-enabling recovery.

### Running tests

Use the repository's bundled Ruby dependencies with OpenStudio's Ruby bindings available. The tested SDK/dependency baseline is OpenStudio 3.10.0, Ruby 3.2, and openstudio-standards 0.8.2. No weather download or EnergyPlus simulation is required.

From the repository root:

```bash
# All 22 independent measures
bundle exec rake test_hvac

# One local suite
bundle exec ruby lib/measures/hvac_doas/tests/hvac_doas_test.rb --verbose

# One scenario
bundle exec ruby lib/measures/hvac_doas/tests/hvac_doas_test.rb --name test_default_create_and_forward_translation

# Select a suite through Rake
bundle exec rake test_hvac TEST=lib/measures/modify_existing_plant_equipment/tests/modify_existing_plant_equipment_test.rb

# Existing cross-measure integration suite remains separate
bundle exec rake spec
```

If the Windows Bundler launcher causes problems, invoke Ruby directly with Bundler preloaded:

```powershell
& 'C:\Ruby32-x64\bin\ruby.exe' -rbundler/setup -S rake test_hvac
& 'C:\Ruby32-x64\bin\ruby.exe' -rbundler/setup lib/measures/hvac_doas/tests/hvac_doas_test.rb --verbose
```

Adjust the interpreter location for the local installation. The direct suites require the repository or installed gem layout, including the shared test support directory; copying only a measure directory does not copy the shared harness. Production measures do not depend on this harness.

### What is checked

Each topology suite includes these common scenarios:

| Scenario | Checks |
| --- | --- |
| Argument contract | Names, operation choices/default, and all three supported standards templates |
| Default creation | All fixture zones served by the correct equipment; EnergyPlus forward translation has no errors and retains zone equipment connections |
| Explicit multi-zone scope, 2013 template | Whitespace and duplicate names handled; unselected zone equipment preserved |
| Single-zone scope, 2016 template | Correct system created only in the selected zone |
| Replacement, default 2019 template | Selected existing air loop removed; zone equipment replaced or retained as appropriate; unrelated zone equipment and plant loop preserved |
| Served-zone creation | Explicit failure without partial model changes |
| Partial shared-loop replacement | Explicit failure without removing shared equipment |
| Mixed valid/missing zone names | Failure before any changes |
| Blank replacement scope | Failure without destroying existing equipment |
| No thermal zones | Explicit failure |

Topology-specific assertions inspect terminal/unit types, zone connections, heating/cooling coil types and plant connections. Additional tests cover DOAS/ventilation priority, a connected supply fan, elimination of duplicate zone-unit outdoor air, radiant surface requirements, and rejection of partial VRF outdoor-unit replacement.

Modifier suites check:

- Every supported plant capacity/efficiency property, including kW-to-W and ton-to-W conversion.
- All eight equipment efficiency metrics, plus both speeds of two-speed DX cooling coils.
- Sensible/latent effectiveness in heating and cooling at both airflow levels, inclusive 0 and 1 boundaries, repeated disabling/restoration, and unsupported effectiveness curves.
- Supply-air temperatures, all six economizer types, combined changes, no-op/NA behavior, missing electronic-enthalpy curves, and warnings for loops without outdoor air.
- Heating, chilled-water, and radiant loop design temperatures.
- Exact-name scope, multiple/duplicate names, preservation of unselected objects, missing names, invalid numeric bounds where defined, and incompatible object/property combinations.

Every intentional rejection verifies the complete serialized model is unchanged, rather than only checking an object count. Supported mixed-object updates verify the incompatible object is preserved and a warning is recorded.

These are model-editing unit tests with forward-translation smoke checks, **not** annual energy, sizing, comfort, or equipment-performance validation. The existing RSpec suite covers additional cross-measure interactions and orphaned-plant cleanup.

### Inspecting artifacts

Every call to the measure writes into its own local test directory:

```text
tests/output/<test_method>/<invocation_number>/
  in.osm       # model immediately before the measure runs
  out.osm      # model after the run, including failed runs
  result.json  # supplied argument overrides, return value, status, logs, exception if any
```

The harness reloads the output with `VersionTranslator` before assertions. The fixture is never overwritten by a test. Invocation numbers distinguish repeated runs within a scenario; rerunning the same test overwrites the corresponding artifacts. The output directories are ignored by Git. Avoid running two copies of the same suite concurrently, since their artifact paths overlap.

An intentional error case has `status: Fail` in its runner report even when the **test passes**. The report records measure execution, not the later Minitest assertion verdict; the test console/exit code is authoritative. Unexpected Ruby exceptions also leave diagnostic artifacts and are re-raised as test errors.

CI runs the local suites alongside RSpec and archives local test artifacts if validation fails.

### Fixtures and maintenance

Topology inputs have three named, unserved zones (`Zone One`, `Zone Two`, `Zone Three`) with floor/wall/roof geometry, constructions, dual-setpoint thermostats, lights, outdoor-air specifications, design days, and a fixed calendar year. Tests add existing baseboards or air loops in memory to stage replacement/conflict cases.

Modifier inputs include two separately named air systems with heat recovery and heating/cooling plants, allowing targeted changes to be checked against untouched equipment. The efficiency fixture also contains deliberately isolated component pairs for every supported efficiency setter. These small inputs are unit-test fixtures, not complete simulation-ready reference buildings.

Tests fail immediately if their fixture is missing or unreadable; there is no fallback to an empty model. Normal test runs **do not** regenerate fixtures.

To deliberately regenerate all 22 fixtures after changing their design:

```bash
bundle exec rake hvac_test_fixtures
bundle exec rake test_hvac
```

This overwrites the input models using the installed SDK; review and commit those changes together with the fixture-generator changes. OpenStudio creates fresh UUIDs, so regeneration can produce a large diff even without geometry changes.

Shared test-only code lives in:

- [Runner, artifact, and assertion helpers](../lib/openstudio/buildingsync_measures/test_support/hvac_measure_test.rb).
- [Reusable topology/ventilation scenarios](../lib/openstudio/buildingsync_measures/test_support/hvac_topology_tests.rb).
- [Reusable modifier validation scenarios](../lib/openstudio/buildingsync_measures/test_support/hvac_modifier_tests.rb).
- [Explicit fixture generator](../lib/openstudio/buildingsync_measures/test_support/generate_hvac_fixtures.rb).

To extend coverage, add a `test_*` method to the relevant local suite, load the fixture through the inherited setup, call `run_measure`, and assert the resulting model properties. Keep shared behavior in the harness, and topology/property-specific expectations in the local test file.

## Deprecation status

`modify_hvac` is retained temporarily so existing workflows can migrate. It should not be selected by new workflows. Removal of the legacy directory, its direct test, and its package inventory entry is a separate breaking-release step.
