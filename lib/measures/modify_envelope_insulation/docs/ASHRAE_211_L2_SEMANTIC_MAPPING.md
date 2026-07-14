# Semantic Mapping: modify_envelope_insulation to ASHRAE Standard 211 Level 2 Audit

## Purpose

This document maps the `modify_envelope_insulation` OpenStudio measure to the envelope-related information needs typically associated with an ASHRAE Standard 211 Level 2 (L2) energy audit workflow.

The intent is semantic alignment, not a claim of full ASHRAE 211 compliance. This measure is a model transformation tool that applies envelope thermal-performance assumptions to an OpenStudio model. An L2 audit still requires field data collection, engineering review, economic analysis, and reporting outside this measure.

## ASHRAE 211 Reference

- ASHRAE Standard 211, Section 6.2.1.2, Building Envelope

## Measure Summary

The measure modifies exterior opaque envelope constructions by increasing insulation performance to user-specified overall assembly targets. It supports:

- Exterior walls
- Roofs and ceilings
- Floors and foundations

For each surface category, the user can provide either:

- Target R-value
- Target U-value, which the measure converts to R-value using `R = 1 / U`

The measure does not let the user directly edit full construction makeup, layer ordering, material properties by name, area-weighted assembly metadata, or component-by-component audit records.

Instead, it updates the most likely insulation layer in each applicable construction by changing:

- `StandardOpaqueMaterial` thickness, or
- `MasslessOpaqueMaterial` thermal resistance

In other words, the user-facing capability is limited to overall opaque assembly R-value or U-value targets for walls, roofs, and floors. Construction-level handling and reporting in this document refer only to how the measure infers existing assembly thermal resistance from the OpenStudio model and logs what it changed during execution.

## Semantic Mapping

| Measure concept | Measure implementation | ASHRAE 211 L2 audit concept | Mapping interpretation |
| --- | --- | --- | --- |
| Exterior wall target thermal performance | `wall_target_rvalue` or `wall_target_uvalue` | Opaque wall assembly thermal characteristics identified during building envelope review | Represents a normalized modeling input for wall insulation improvement scenarios derived from audit findings or ECM assumptions. |
| Roof/ceiling target thermal performance | `roof_target_rvalue` or `roof_target_uvalue` | Roof and ceiling thermal characteristics documented in envelope assessment | Represents modeled post-retrofit or proposed-condition roof insulation performance. |
| Floor/foundation target thermal performance | `floor_target_rvalue` or `floor_target_uvalue` | Slab, floor, or foundation thermal boundary characteristics | Represents modeled improvement assumptions for below-grade or exposed floor assemblies where insulation upgrades are considered. |
| R-value / U-value dual input path | Priority logic uses R-value first, otherwise converts U-value to R-value | Audit data may be documented using either U-factor or R-value depending on source documentation | Normalizes different audit data formats into a single internal thermal resistance basis for simulation. |
| Current construction evaluation | Sums thermal resistance across material layers in each construction | Existing condition characterization of envelope assemblies | Approximates baseline envelope thermal performance from model construction definitions so the measure can compare current overall assembly R-value against the requested target. |
| Insulation layer adjustment | Changes insulation thickness or massless thermal resistance | Energy conservation measure definition for envelope insulation upgrade | Encodes a candidate retrofit action in the simulation model so the ECM can be analyzed. |
| Exterior-only filtering | Applies only to exterior surfaces with `OutsideBoundaryCondition == 'Outdoors'` | Audit focus on the building thermal boundary | Aligns changes to envelope elements that affect heat transfer to outdoor conditions. |
| Unique construction-based modification | Modifies each distinct construction once per applicable surface type | Audit analysis at assembly/system level rather than per individual polygon | Keeps the ECM representation consistent across surfaces sharing the same assembly. |
| Informational reporting | Registers initial condition, per-construction actions, warnings, and final condition in the OpenStudio runner output | Audit traceability and documentation of assumptions | Provides lightweight run-time traceability only; it is not a structured envelope report and does not produce ASHRAE 211 reporting deliverables. |

## What This Measure Supports in an L2 Audit Workflow

This measure is best understood as supporting the analysis phase of an L2 audit, especially for envelope-related energy conservation measures.

More specifically, it supports parameterizing overall opaque assembly performance targets in an energy model. It does not support detailed envelope inventory authoring or comprehensive audit reporting.

It helps translate audit outputs such as:

- Existing envelope assembly descriptions already represented in the baseline OpenStudio model
- Proposed insulation upgrade targets for walls, roofs, or floors
- Manufacturer, code, or design targets expressed as R-values or U-values

Into simulation-ready changes that can be used to estimate:

- Energy impact
- End-use impact
- Utility cost impact when paired with tariff assumptions
- Relative savings between baseline and improved envelope cases

It should not be interpreted as a measure that directly manages all envelope construction attributes described in audit documentation.

## L2 Requirements Not Covered by This Measure

This measure does not itself perform the broader ASHRAE 211 Level 2 audit functions below:

- Site inspection or field verification of envelope conditions
- Infrared thermography, destructive investigation, or moisture assessment
- Documentation of assembly area, orientation, observed deterioration, or installation quality
- Ventilation, infiltration, and air leakage diagnostics
- Fenestration assessment for windows, skylights, and shading systems
- Economic screening, life-cycle cost analysis, or payback calculation
- Prioritization of ECMs across interacting systems
- Final audit report generation

## Practical Interpretation for This Repository

Within this repository, the measure should be treated as an envelope ECM implementation component.

Recommended semantic role:

- Audit input source: ASHRAE 211 L2 field findings and engineering assumptions
- Translation layer: this measure converts those findings into model-ready envelope targets
- Analysis output: downstream workflow compares baseline and modified runs to quantify impact

## Suggested Data Handoff from Audit to Measure

To use this measure consistently in an ASHRAE 211 L2 style workflow, the audit process should hand off at least:

- Envelope component type: wall, roof, or floor
- Existing condition description
- Proposed insulation target as R-value or U-value
- Basis for target: observed condition, design intent, code target, or ECM recommendation
- Modeling notes for exclusions, assumptions, and applicability

Door and window upgrades are intentionally excluded from this measure and should be handled in a separate fenestration-focused measure.

## Conclusion

The `modify_envelope_insulation` measure aligns most closely with the envelope ECM analysis portion of an ASHRAE 211 Level 2 audit. It does not satisfy the full audit standard on its own, but it provides a clear mechanism for turning envelope upgrade recommendations into repeatable OpenStudio model changes for energy analysis.