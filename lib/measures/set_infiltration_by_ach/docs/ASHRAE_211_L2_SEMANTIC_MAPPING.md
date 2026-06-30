# Semantic Mapping: set_infiltration_by_ach to ASHRAE Standard 211 Level 2 Audit

## Purpose

This document maps the `set_infiltration_by_ach` OpenStudio measure to infiltration-related information needs typically associated with an ASHRAE Standard 211 Level 2 (L2) energy audit workflow.

This is semantic alignment, not a claim of full ASHRAE 211 compliance. The measure is a model transformation utility for ACH-based infiltration assumptions. A full L2 audit still requires field data collection, diagnostics, engineering interpretation, and reporting outside this measure.

## ASHRAE 211 Reference

- ASHRAE Standard 211, Section 6.2.1.2.e, Building Envelope - Overall enclosure tightness

## Measure Summary

The measure updates all `SpaceInfiltrationDesignFlowRate` objects to use ACH inputs via the AirChanges/Hour method.

Supported ACH input paths:

- `ACH50` input, converted to natural ACH using `natural_ach = ach_value / n_factor`
- `ACH_natural` input, applied directly

Behavior summary:

- Applies one derived natural ACH value to all existing `SpaceInfiltrationDesignFlowRate` objects
- Updates objects in place; does not create or delete infiltration objects
- Returns not applicable when no infiltration objects exist

## Semantic Mapping

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| ACH50 infiltration input | `input_type = ACH50`, `ach_value`, `n_factor` | Envelope air leakage test result representation | Converts pressure-specific blower-door style ACH input into a natural-condition ACH assumption for simulation. |
| Natural ACH infiltration input | `input_type = ACH_natural`, `ach_value` | Existing-condition or proposed-condition natural infiltration assumption | Applies natural infiltration assumptions directly when already normalized outside the measure. |
| ACH conversion factor | `n_factor` divisor in ACH50 conversion | Engineering normalization between test-condition leakage and natural infiltration estimate | Provides a simple conversion control for consistent scenario assumptions. |
| Infiltration method assignment | Sets `SpaceInfiltrationDesignFlowRate` via `setAirChangesperHour` | Simulation model parameterization of infiltration | Encodes audit-derived ACH assumptions in model objects consumed by simulation. |
| Bulk object update | Iterates all infiltration objects in the model | Standardized baseline/proposed scenario treatment | Applies a consistent ACH assumption across modeled infiltration objects unless object-level differentiation is handled elsewhere. |
| Input validation and traceability | Positive-value checks and runner initial/final info | QA/QC and assumption traceability in analysis workflow | Improves transparency for simulation runs, but is not a full audit artifact. |

## What This Measure Supports in an L2 Audit Workflow

This measure supports the L2 analysis phase by translating ACH-based infiltration assumptions into simulation-ready model inputs.

It is useful for:

- Applying ACH assumptions derived from envelope assessment findings
- Running baseline versus ECM sensitivity cases for infiltration reduction scenarios
- Keeping ACH-driven infiltration parameterization consistent across model infiltration objects

## What Is Not Mapped or Covered Here

This measure intentionally does not handle CFM-based infiltration data paths.

Not covered in this measure:

- CFM-at-pressure style inputs and CFM-derived infiltration correlations
- Geometry- or pressure-regime-specific CFM modeling methods
- Detailed leakage pathway diagnostics and component-level attribution
- Full field testing workflow, QA/QC, and final audit reporting

CFM-related data and correlation workflows are handled in a separate measure:

- `set_nist_infiltration_correlations`

## Practical Interpretation for This Repository

Within this repository, `set_infiltration_by_ach` should be treated as the ACH-only infiltration translation layer.

Recommended split of responsibility:

- ACH pathway: `set_infiltration_by_ach`
- CFM/correlation pathway: `set_nist_infiltration_correlations`

## Suggested Data Handoff from Audit to Measure

For consistent L2 workflow use, hand off at minimum:

- Input type (`ACH50` or `ACH_natural`)
- ACH value
- n-factor when using `ACH50`
- Basis/source of assumption (test data, benchmark, engineering assumption)
- Scenario designation (baseline or proposed/ECM)

## Conclusion

The `set_infiltration_by_ach` measure aligns with the ACH-based infiltration modeling portion of ASHRAE 211 L2 analysis. It does not cover CFM-based infiltration workflows; those are intentionally handled by `set_nist_infiltration_correlations`.
