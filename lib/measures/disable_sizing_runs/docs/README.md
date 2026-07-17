# Disable Sizing Runs - Measure Documentation

## Description

The `disable_sizing_runs` measure updates the model `SimulationControl` object so annual weather-file simulation can run when the model has no design-day sizing periods. It disables sizing-period simulation, keeps weather-file run periods enabled, and disables zone, system, and plant sizing calculations when those setters are available in the installed OpenStudio version.

This measure has no user arguments. It is intended as a workflow utility rather than a BuildingSync data translation measure.

## Guide to Use

Add this measure near the end of an OpenStudio workflow, after measures that create or modify HVAC systems and before simulation. It is useful for BOSS or audit-translation workflows where the seed model or generated model is intended to run only against the weather-file run period.

Expected behavior:

- `RunSimulationforSizingPeriods` is set to `false`.
- `RunSimulationforWeatherFileRunPeriods` is set to `true`.
- Zone, system, and plant sizing calculations are disabled when supported by the OpenStudio SDK.
- The measure reports a final condition and exits successfully.

## BuildingSync Reader Mapping

This table follows the BOSS README mapping style. The `set by function in BuildingSyncReader` column is a placeholder until reader methods are finalized.

Read `.../Facility` as `/BuildingSync/Facilities/Facility`, `.../Systems` as `/BuildingSync/Facilities/Facility/Systems`, `.../Site` as `/BuildingSync/Facilities/Facility/Sites/Site`, and `.../Building` as `/BuildingSync/Facilities/Facility/Sites/Site/Buildings/Building`.

| Measure | Argument | set by function in BuildingSyncReader | Read from BuildingSync |
|---|---|---|---|
| disable_sizing_runs |  |  | No measure arguments; workflow/model-control step. |

## Example OSW Step

```json
{
  "measure_dir_name": "disable_sizing_runs",
  "arguments": {}
}
```
