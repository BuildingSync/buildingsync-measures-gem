# Modify Envelope Insulation

## Purpose

Set target thermal performance for exterior walls, roofs, and exterior floors by increasing the insulation layer in each applicable OpenStudio construction.

## Summary

- Supply an R-value or U-factor for each surface category; use `0` to skip it.
- If both values are positive for one category, the R-value wins and the U-factor is ignored.
- The measure expects SI units: R in m²·K/W and U in W/m²·K.
- It changes only surfaces with `OutsideBoundaryCondition == 'Outdoors'` and only increases modeled resistance; it does not reduce insulation.
- One argument value is applied to every construction in that category. If XML links multiple systems, the reader must select or aggregate them before calling the measure.

## Reference

- ASHRAE 211 L2 context: [ASHRAE_211_L2_SEMANTIC_MAPPING.md](ASHRAE_211_L2_SEMANTIC_MAPPING.md)
- Implementation: [../measure.rb](../measure.rb)

## Quick Use

1. Follow each section reference (`WallID`, `RoofID`, or `FoundationID`) to its system under `Facility/Systems`.
2. Prefer the assembly R-value. Use the U-factor only when R is unavailable or the workflow explicitly chooses U.
3. Convert BuildingSync 2.7.0 IP values to the SI units expected by the measure.
4. If multiple linked systems exist, choose an explicit policy—for example, the proposed system, the dominant-area system, or an area-weighted value.

The paths below omit the XML namespace prefix and use:

- `SYS` = `/BuildingSync/Facilities/Facility/Systems`
- `BLDG` = `/BuildingSync/Facilities/Facility/Sites/Site/Buildings/Building`

## BuildingSync Reader Mapping

| Argument | Candidate BuildingSync XML field | Selection and conversion rule | BuildingSyncReader function |
|---|---|---|---|
| `wall_target_rvalue` | `SYS/WallSystems/WallSystem[@ID=$wall_ref]/WallRValue`; `$wall_ref` comes from `BLDG/Sections/Section/Sides/Side/WallIDs/WallID/@IDref` | Preferred wall input. Convert IP R to SI: `R_SI = R_IP × 0.176110`. If several wall IDs are used, select one target or area-weight using each `WallID/WallArea`. A possible fallback is `WallInsulations/WallInsulation/WallInsulationRValue`, but that is insulation-only and requires an assembly-level derivation. | TBD |
| `wall_target_uvalue` | `SYS/WallSystems/WallSystem[@ID=$wall_ref]/WallUFactor` | Convert `U_SI = U_IP × 5.678263`. Set this only when `wall_target_rvalue` is `0`; R wins if both are positive. | TBD |
| `roof_target_rvalue` | `SYS/RoofSystems/RoofSystem[@ID=$roof_ref]/RoofRValue`; `$roof_ref` comes from `BLDG/Sections/Section/Roofs/Roof/RoofID/@IDref` | Preferred roof input. Convert `R_SI = R_IP × 0.176110`. For multiple sections, select or area-weight using `RoofID/RoofArea`. `RoofInsulations/RoofInsulation/RoofInsulationRValue` is an insulation-only fallback. | TBD |
| `roof_target_uvalue` | `SYS/RoofSystems/RoofSystem[@ID=$roof_ref]/RoofUFactor` | Convert `U_SI = U_IP × 5.678263`. Set this only when `roof_target_rvalue` is `0`. | TBD |
| `floor_target_rvalue` | `SYS/FoundationSystems/FoundationSystem[@ID=$foundation_ref]/GroundCouplings/GroundCoupling/SlabOnGrade/SlabRValue` or `.../Crawlspace/CrawlspaceVenting/Ventilated/FloorRValue`; `$foundation_ref` comes from `BLDG/Sections/Section/FoundationID/@IDref` | Use the field from the applicable ground-coupling branch. Convert `R_SI = R_IP × 0.176110`. For multiple sections, select or area-weight using `FoundationID/FoundationArea`. | TBD |
| `floor_target_uvalue` | `SYS/FoundationSystems/FoundationSystem[@ID=$foundation_ref]/GroundCouplings/GroundCoupling/SlabOnGrade/SlabUFactor` or `.../Crawlspace/CrawlspaceVenting/Ventilated/FloorUFactor` | Use the field paired with the selected foundation branch. Convert `U_SI = U_IP × 5.678263`. Set this only when `floor_target_rvalue` is `0`. | TBD |

BuildingSync R-values exclude air films, while its assembly U-factors include boundary films. Review the chosen conversion/target basis before mixing R-derived and U-derived targets.

## Example

A linked `WallSystem` with `WallRValue = 13` yields `wall_target_rvalue ≈ 2.289 m²·K/W`; set `wall_target_uvalue = 0` so the R target is unambiguous.
