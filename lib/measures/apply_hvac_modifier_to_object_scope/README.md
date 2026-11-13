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
| `modifier_arguments_json` | JSON object of the modifier's arguments other than its target-names argument, e.g. `{"efficiency_metric":"dx_cooling_cop","efficiency_value":4.0}`. Unknown keys and the target-names key are rejected. |

`all_matching_objects` resolves:

| Modifier | Objects |
|---|---|
| `modify_existing_air_loop_controls` | All air loops. |
| `modify_existing_heat_recovery` | All air-to-air sensible and latent heat exchangers. |
| `modify_existing_hvac_equipment_efficiencies` | Objects of the type `efficiency_metric` changes; the metric is required. |
| `modify_existing_plant_equipment` | Hot-water boilers for `boiler_*` properties, electric EIR chillers for `chiller_*`; the property is required. |
| `modify_existing_plant_loop_temperatures` | Plant loops whose sizing loop type is `plant_loop_type`. |

The measure fails when nothing matches. The modifiers split target names on commas, so names containing commas are rejected. The modifier keeps its own checks, including missing explicit names.

This measure loads the selected modifier from a sibling directory, so the `modify_existing_*` measures from this gem must be installed in the same measures directory.

## Tests

```bash
bundle exec ruby lib/measures/apply_hvac_modifier_to_object_scope/tests/apply_hvac_modifier_to_object_scope_test.rb
```
