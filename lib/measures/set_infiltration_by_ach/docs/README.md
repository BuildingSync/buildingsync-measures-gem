# Set Infiltration By ACH - Measure Documentation

## Description

The `set_infiltration_by_ach` measure bulk-updates existing `SpaceInfiltrationDesignFlowRate` objects to use the AirChanges/Hour calculation method. It accepts either a blower-door-style `ACH50` value, converted to natural ACH using `n_factor`, or an already-normalized `ACH_natural` value.

This measure updates infiltration objects in place. It does not create, delete, or zone-scope infiltration objects. If the model has no infiltration objects, the measure reports not applicable.

For ASHRAE 211 Level 2 semantic context, see [ashrae-211-l2-semantic-mapping.md](ashrae-211-l2-semantic-mapping.md).

## Guide to Use

Use this measure when an audit workflow has produced an ACH-based infiltration assumption that should be applied consistently across the model.

Typical use cases:

- Apply an ACH50 test result using the default commercial `n_factor` of `20.0`.
- Apply an already-derived natural ACH value directly.
- Run baseline versus proposed infiltration-reduction scenarios by changing `ach_value`.

Recommended workflow placement:

- Run after the seed model contains infiltration objects.
- Run before simulation and before reporting measures.
- Pair with separate measures if CFM-based infiltration correlations or component-level leakage modeling are needed.

## Arguments

| Argument | Type | Default | Description |
|---|---|---|---|
| `input_type` | choice | `ACH50` | Use `ACH50` to convert a pressure-test value to natural ACH, or `ACH_natural` to apply the value directly. |
| `ach_value` | double | `3.0` | ACH value at the selected input basis. Must be greater than zero. |
| `n_factor` | double | `20.0` | Divisor used only for `ACH50`: `natural_ach = ach_value / n_factor`. Must be greater than zero. |

## BuildingSync Reader Mapping

This table follows the BOSS README mapping style. The `set by function in BuildingSyncReader` column is a placeholder until reader methods are finalized.

Read `.../Facility` as `/BuildingSync/Facilities/Facility`, `.../Systems` as `/BuildingSync/Facilities/Facility/Systems`, `.../Site` as `/BuildingSync/Facilities/Facility/Sites/Site`, and `.../Building` as `/BuildingSync/Facilities/Facility/Sites/Site/Buildings/Building`.

| Measure | Argument | set by function in BuildingSyncReader | Read from BuildingSync |
|---|---|---|---|
| set_infiltration_by_ach |  |  |  |
|  | `input_type` | TBD | Candidate derived from available infiltration representation: ACH50-style test data versus natural ACH assumption. Possible source near `.../Building` envelope/infiltration or air-leakage audit fields. |
|  | `ach_value` | TBD | Candidate ACH value from envelope air leakage or infiltration audit data, such as an ACH50 test result or natural ACH assumption associated with `.../Building`. |
|  | `n_factor` | TBD | Candidate engineering assumption, not always explicit in BuildingSync; may be hard-coded/defaulted or read from analyst notes/measure metadata. |

## Example OSW Step

```json
{
  "measure_dir_name": "set_infiltration_by_ach",
  "arguments": {
    "input_type": "ACH50",
    "ach_value": 3.0,
    "n_factor": 20.0
  }
}
```