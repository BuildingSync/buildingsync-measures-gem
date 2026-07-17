# Semantic Mapping: modify_schedules to ASHRAE Standard 211 Level 2 Audit

## Purpose

This document maps the `modify_schedules` OpenStudio measure to schedule- and operation-related information needs typically associated with an ASHRAE Standard 211 Level 2 (L2) energy audit workflow.

This is semantic alignment, not a claim of full ASHRAE 211 compliance. The measure transforms operational assumptions into model schedules for simulation. A full L2 audit still requires site investigation, data quality checks, engineering interpretation, economics, and reporting outside this measure.

## ASHRAE 211 Reference

- ASHRAE Standard 211, Section 6.2.1.1.e, Building Information - Schedules

## Measure Summary

The measure creates or updates `ScheduleRuleset` objects from BuildingSync-aligned schedule payloads and applies them to model targets.

Primary supported targets:

- Occupancy
- Lighting
- Plug/electric equipment
- Gas equipment
- HVAC availability
- Optional additional categories such as service water

Key behavioral semantics:

- Accepts either JSON payloads or compact semicolon-delimited text payloads
- Parses day-type intervals with start time, end time, and fractional/percent values
- Normalizes values to fraction range `[0, 1]`
- Applies schedules via building and space type default schedule sets and equipment/air loop objects
- Optionally replaces existing matching schedules

## Semantic Mapping

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| Occupancy operating profile | `occupancy_schedule_json` mapped to `occupancy` target | Documented occupancy patterns, operating hours, and diversity assumptions | Represents occupancy schedule assumptions used to model baseline or post-ECM operational behavior. |
| Lighting operating profile | `lighting_schedule_json` mapped to `lighting` target | Lighting operating schedules and control behavior identified in audit | Represents modeled lighting usage timing used for calibration or ECM scenario evaluation. |
| Plug load operating profile | `electric_equipment_schedule_json` mapped to `electric_equipment` target | Plug/process load operating patterns in end-use characterization | Converts audit-derived plug load timing assumptions into simulation-ready schedules. |
| Gas equipment profile | `gas_equipment_schedule_json` mapped to `gas_equipment` target | Fuel-based equipment operational schedules documented during L2 assessment | Captures gas equipment schedule assumptions for baseline/proposed analyses. |
| HVAC availability profile | `hvac_availability_schedule_json` mapped to `hvac_availability` target and assigned to air loops | HVAC system operating schedules and availability windows from controls review | Represents AHU/system on-off availability assumptions for energy and demand impact analysis. |
| Additional schedule categories | `additional_schedules_json` with extensible `target` mapping, including `service_water` | Additional end-use schedule assumptions beyond core categories | Supports extending L2 operational assumptions into custom/end-use model components. |
| BuildingSync-aligned schedule details | Day type + start/end time + partial operation percent parsing | Audit data exchange and interoperability of schedule observations | Provides a structured handoff path from audit data formats to simulation input objects. |
| Replace-existing control | `replace_existing` determines overwrite vs preserve behavior | Baseline integrity and scenario-control decisions in audit workflow | Supports either conservative reuse of existing schedules or explicit replacement for scenario testing. |
| Day-type handling | Weekday/default, Saturday, Sunday, weekend expansion, holiday profile | Typical operating-day categorization in audit documentation | Aligns schedule semantics with common audit reporting of weekday/weekend/holiday operations. |
| Fraction type limits and clipping | Enforces fraction schedules with values constrained to `[0,1]` | Data validation and plausibility screening for operational assumptions | Prevents invalid operational schedule magnitudes from propagating into simulation runs. |
| Assignment to model objects | Applies via default schedule set, internal load objects, air loops, and water-use equipment | Translation of observed/control assumptions to modeled systems and end uses | Encodes operational ECM or baseline assumptions where simulation engines consume schedules. |
| Run-level reporting | Initial/final condition with counts of schedules and affected objects | Audit traceability of analytical assumptions and modeled scope | Improves transparency of what assumptions were applied, but is not a complete L2 report artifact. |

## What This Measure Supports in an L2 Audit Workflow

This measure supports the analysis phase of an L2 audit by converting operational schedule findings into consistent simulation inputs.

It is particularly useful for:

- Baseline model schedule normalization based on audit interviews, trend logs, or BMS exports
- ECM scenario testing for schedule optimization, setbacks, and reduced operating hours
- Translating BuildingSync-like schedule payloads into OpenStudio-compatible schedule objects

When paired with complete baseline/proposed workflows, it supports estimation of:

- Whole-building and end-use energy changes
- Demand profile and runtime changes
- Utility cost impacts when tariffs are included downstream

## L2 Requirements Not Covered by This Measure

This measure does not by itself perform the broader ASHRAE 211 Level 2 audit activities below:

- Field data collection, interviews, and controls sequence verification
- Trend data QA/QC, interval data cleansing, and uncertainty treatment
- Functional testing of controls or commissioning diagnostics
- Equipment inventory completeness and nameplate verification
- Weather normalization and utility bill reconciliation/calibration methodology
- Economic screening, financial metrics, and implementation planning
- Final audit narrative/report package production

## Practical Interpretation for This Repository

Within this repository, `modify_schedules` should be treated as an operational-assumption translation layer.

Recommended semantic role:

- Audit input source: L2 findings on occupancy, loads, and controls schedules
- Translation layer: this measure converts those findings to model schedule objects and assignments
- Analysis output: downstream baseline-versus-modified simulations quantify impacts

## Suggested Data Handoff from Audit to Measure

For consistent use in an ASHRAE 211 L2 style workflow, pass at minimum:

- Schedule target category (occupancy, lighting, plug, gas, HVAC availability, service water, etc.)
- Day-type schedule intervals with start/end timestamps
- Value semantics and units (fraction vs percent)
- Basis/source (trend data, BMS export, interview, controls sequence)
- Scenario designation (existing baseline vs proposed operational ECM)
- Notes on exceptions, overrides, and known data-quality limitations

## Conclusion

The `modify_schedules` measure aligns strongly with the operational scheduling portion of L2 audit analysis. It does not replace full ASHRAE 211 audit requirements, but it provides a repeatable mechanism to encode and apply audit-derived schedule assumptions in OpenStudio simulations.