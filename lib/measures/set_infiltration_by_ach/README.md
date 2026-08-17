# Set Infiltration By ACH

## Purpose

Apply one ACH-based infiltration rate to all existing `SpaceInfiltrationDesignFlowRate` objects in an OpenStudio model.

## Summary

- `ACH50` is converted to natural ACH with `natural_ach = ach_value / n_factor`.
- `ACH_natural` is applied directly; `n_factor` is ignored.
- Both numeric arguments must be greater than zero.
- The measure updates existing infiltration objects only; it does not create them or preserve different rates by premise.

## Reference

- ASHRAE 211 L2 context: [ASHRAE_211_L2_SEMANTIC_MAPPING.md](ASHRAE_211_L2_SEMANTIC_MAPPING.md)
- Implementation: [../measure.rb](../measure.rb)

## Quick Use

Select the `AirInfiltrationSystem` linked to the modeled building through `LinkedPremises`, then read its value and units. If several linked records exist, choose an explicit baseline/proposed or aggregation policy before calling the measure.

The paths below use `AIS` for `/BuildingSync/Facilities/Facility/Systems/AirInfiltrationSystems/AirInfiltrationSystem`.

## BuildingSync Reader Mapping

| Argument | Candidate BuildingSync XML field | Selection and conversion rule | BuildingSyncReader function |
|---|---|---|---|
| `input_type` | `AIS/AirInfiltrationValueUnits` | Map `ACH50` to `ACH50`; map `ACHnatural` to `ACH_natural`. `CFM25`, `CFM50`, `CFM75`, `CFMnatural`, and `Effective Leakage Area` are not supported by this measure and require another conversion/measure. | TBD |
| `ach_value` | `AIS/AirInfiltrationValue` | Use the value from the selected building-linked record. No unit conversion is needed for `ACH50` or `ACHnatural`. | TBD |
| `n_factor` | No direct BuildingSync 2.7.0 field | Required only for `ACH50`. Use a documented engineering assumption; the measure default is `20.0`. Do not infer it from `AirInfiltrationTest` alone. | TBD |

`AirInfiltrationTest` (`Blower door`, `Tracer gas`, `Checklist`, or `Other`) is useful provenance but does not replace `AirInfiltrationValueUnits`. The measure cannot represent premise-specific rates because it applies one result to every existing infiltration object.

## OSW Examples

ACH50:

```json
{
  "measure_dir_name": "set_infiltration_by_ach",
  "arguments": { "input_type": "ACH50", "ach_value": 3.0, "n_factor": 20.0 }
}
```

Natural ACH:

```json
{
  "measure_dir_name": "set_infiltration_by_ach",
  "arguments": { "input_type": "ACH_natural", "ach_value": 0.15, "n_factor": 20.0 }
}
```
