# Disable Sizing Runs

## Purpose

Allow an annual weather-file simulation to run without design-day sizing periods.

## Summary

This measure has no arguments. It disables sizing-period, zone, system, and plant sizing calculations when supported by the installed OpenStudio SDK, and keeps weather-file run periods enabled. Run it after model/HVAC changes and before simulation.

## Reference

- Implementation: [../measure.rb](../measure.rb)

## BuildingSync Reader Mapping

This is a workflow-control measure; it does not read audit data from the XML.

| Argument | BuildingSync XML field | How to use it | BuildingSyncReader function |
|---|---|---|---|
| None | None | Add the measure when the generated workflow should run weather periods without sizing periods. | TBD |

## OSW Step

```json
{
  "measure_dir_name": "disable_sizing_runs",
  "arguments": {}
}
```
