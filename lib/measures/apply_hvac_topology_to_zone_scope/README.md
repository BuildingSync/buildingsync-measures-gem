# Apply HVAC Topology To Zone Scope

Runs one split HVAC topology measure on thermal-zone names resolved from the model at run time.

OSW step arguments are fixed when a workflow is written, and a measure cannot change a later step's arguments. A consumer that knows the HVAC scope but not the model's zone names, such as BuildingSync premises linked to the whole building, uses this measure instead of calling the topology measure directly.

## Arguments

| Argument | Values |
|---|---|
| `topology_measure` | One of the 17 `hvac_*` topology measure directory names. |
| `operation` | `create` (default) or `replace`; passed to the topology measure. |
| `zone_scope` | `all_model_zones`: every thermal zone in the model, by exact name. |
| `standards_template` | `90.1-2013`, `90.1-2016`, or `90.1-2019` (default). |

The topology measure keeps its own checks: `create` fails on served zones, and `replace` receives an explicit, complete zone list. The measure fails when the model has no thermal zones.

## Tests

```bash
bundle exec ruby lib/measures/apply_hvac_topology_to_zone_scope/tests/apply_hvac_topology_to_zone_scope_test.rb
```
