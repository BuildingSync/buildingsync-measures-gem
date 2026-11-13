# Apply HVAC Topology To Zone Scope

Runs one split HVAC topology measure on thermal-zone names resolved from the model at run time.

OSW step arguments are fixed when a workflow is written, and a measure cannot change a later step's arguments. A consumer that knows the HVAC scope but not the model's zone names, such as BuildingSync premises linked to the whole building, uses this measure instead of calling the topology measure directly.

## Arguments

| Argument | Values |
|---|---|
| `topology_measure` | One of the 17 `hvac_*` topology measure directory names. |
| `operation` | `create` (default) or `replace`; passed to the topology measure. |
| `zone_scope` | `all_model_zones` (default): every thermal zone in the model, by exact name. `explicit_zone_names`: the names in `zone_names_json`. |
| `zone_names_json` | JSON array of exact thermal-zone names, e.g. `["Zone A", "Office, East"]`. Required for `explicit_zone_names`, ignored otherwise. Every name must exist in the model. |
| `standards_template` | `90.1-2013`, `90.1-2016`, or `90.1-2019` (default). |
| `topology_arguments_json` | Optional JSON object of other topology-measure arguments with string values, e.g. `{"supplemental_heating_fuel": "NaturalGas"}`. Must not set `operation`, `target_zone_names`, or `standards_template`; every key must be an argument of the selected topology measure. |

The topology measure keeps its own checks: `create` fails on served zones, and `replace` receives an explicit, complete zone list. Zone names are passed to the topology measure's `target_zone_names` as a JSON array, so names containing commas bind exactly. The measure fails when the model has no thermal zones.

This measure loads the selected topology measure from a sibling directory, so the `hvac_*` measures from this gem must be installed in the same measures directory. It reports an error if the selected one is missing.

## Tests

```bash
bundle exec ruby lib/measures/apply_hvac_topology_to_zone_scope/tests/apply_hvac_topology_to_zone_scope_test.rb
```
