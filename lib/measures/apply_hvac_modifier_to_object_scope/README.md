# Apply HVAC Modifier To Object Scope

Runs one `modify_existing_*` HVAC measure on object names resolved from the model at run time.

OSW step arguments are fixed when a workflow is written, and a measure cannot change a later step's arguments. A consumer that knows which setting to change but not the model's object names, such as BuildingSync premises linked to the whole building, uses this measure instead of calling the modifier directly.

## Arguments

| Argument | Values |
|---|---|
| `modifier_measure` | `modify_existing_air_loop_controls`, `modify_existing_heat_recovery`, `modify_existing_hvac_equipment_efficiencies`, `modify_existing_plant_equipment`, or `modify_existing_plant_loop_temperatures`. |
| `object_scope` | `all_matching_objects` (default): every model object the modifier can change with the given arguments. `explicit_object_names`: the names in `object_names_json`. |
| `object_names_json` | JSON array of exact object names. Required for `explicit_object_names`, ignored otherwise. |
| `plant_loop_type` | `any` (default), `Heating`, `Cooling`, or `Condenser`. Required (not `any`) for `modify_existing_plant_loop_temperatures` with `all_matching_objects`; matches `Sizing:Plant` loop type. |
| `modifier_arguments_json` | JSON object of the modifier's arguments other than its target-names argument, e.g. `{"efficiency_metric":"dx_cooling_cop","efficiency_value":4.0}`. Unknown keys, the target-names key, and values of the wrong JSON type (for example `"4.0"` for a number) are rejected. See the keys below. |

`modifier_arguments_json` keys by modifier (see each modifier's README for defaults and limits):

| Modifier | Keys (JSON type) |
|---|---|
| `modify_existing_air_loop_controls` | `set_supply_air_temperatures` (boolean), `cooling_supply_air_temperature_c` (number), `heating_supply_air_temperature_c` (number), `set_economizer` (boolean), `economizer_control_type` (`NoEconomizer`, `FixedDryBulb`, `FixedEnthalpy`, `DifferentialDryBulb`, `DifferentialEnthalpy`, `ElectronicEnthalpy`), `economizer_high_limit_dry_bulb_temperature_c` (number), `economizer_high_limit_enthalpy_j_kg` (number) |
| `modify_existing_heat_recovery` | `effectiveness_metric` (`sensible_effectiveness`, `latent_effectiveness`), `effectiveness` (number) |
| `modify_existing_hvac_equipment_efficiencies` | `efficiency_metric` (`dx_cooling_cop`, `dx_heating_cop`, `gas_burner_efficiency`, `electric_heating_efficiency`, `water_to_air_cooling_cop`, `water_to_air_heating_cop`, `vrf_cooling_cop`, `vrf_heating_cop`), `efficiency_value` (number) |
| `modify_existing_plant_equipment` | `property` (`boiler_capacity_kw`, `boiler_thermal_efficiency`, `chiller_capacity_tons`, `chiller_reference_cop`), `value` (number) |
| `modify_existing_plant_loop_temperatures` | `design_loop_exit_temperature_c` (number) |

`all_matching_objects` resolves:

| Modifier | Objects |
|---|---|
| `modify_existing_air_loop_controls` | All air loops. |
| `modify_existing_heat_recovery` | All air-to-air sensible and latent heat exchangers. |
| `modify_existing_hvac_equipment_efficiencies` | Objects of the type `efficiency_metric` changes; the metric is required. |
| `modify_existing_plant_equipment` | Hot-water boilers for `boiler_*` properties, electric EIR chillers for `chiller_*`; the property is required. |
| `modify_existing_plant_loop_temperatures` | Plant loops whose sizing loop type is `plant_loop_type`. |

The measure fails when nothing matches. Names are passed to the modifier as a JSON array, so names containing commas work. The modifier keeps its own checks, including missing explicit names.

This measure loads the selected modifier from a sibling directory, so the `modify_existing_*` measures from this gem must be installed in the same measures directory.

## Tests

```bash
bundle exec ruby lib/measures/apply_hvac_modifier_to_object_scope/tests/apply_hvac_modifier_to_object_scope_test.rb
```
