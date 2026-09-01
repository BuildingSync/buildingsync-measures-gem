# Replace HVAC with PTAC

Removes HVAC dedicated to selected zones and installs packaged terminal air conditioners. Unrelated HVAC and plant loops are preserved.

## Use this measure when

- A retrofit or comparison case replaces the complete serving system for selected zones with PTACs.
- Every zone on an affected shared air loop is included.

Do not use it for efficiency-only changes. The measure rejects partial replacement of shared air loops before deleting anything.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Comma-separated exact zones whose HVAC will be replaced | Required |
| `standards_template` | Template used to create replacement PTACs | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged terminal air conditioner (PTAC)"`; associated `Delivery/DeliveryType/ZoneEquipment`; `Delivery/CoolingSourceID/@IDref` joins the records | Require proposed status, the PTAC enum, and zone-equipment delivery for the same premises | Exact enum plus IDREF relationship | High when all records agree |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Packaged Terminal Air Conditioner"` | Use only if proposed L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status/scenario is unclear, the PTAC enum is missing, source-to-delivery IDREF is unresolved, or delivery is central rather than zone equipment | Confirm both the proposed topology and complete existing-system removal scope | Manual classification | Required if any listed condition applies |
| `target_zone_names` | Proposed HVAC/component `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives: `LinkedPremises/Space/LinkedSpaceID/@IDref` and `LinkedPremises/Section/LinkedSectionID/@IDref` | Resolve every served premise; include all zones on shared existing loops | Comma-separated model names | Incomplete linked premises can make replacement unsafe |
| `standards_template` | No direct field | Baseline/retrofit modeling policy | None | Workflow input |

## Usage

1. Resolve all premises served by the replacement system.
2. Ensure the target includes every zone on affected shared loops.
3. Run this measure, then use focused modifiers for audited efficiency values.

## Limitations

Existing plant loops are deliberately preserved. A failed creation after removal is reported but OpenStudio measures are not transactional; use workflow checkpoints for production replacement studies.
