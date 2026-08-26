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
| Replacement selection | Proposed/retrofit `HVACSystem/PrincipalHVACSystemType`; fallback PTAC `DXSystemType` | Consumer selects this measure when the replacement topology is PTAC | Enum mapping only | BuildingSync may distinguish existing and proposed systems through scenario/workflow context |
| `target_zone_names` | Replacement HVAC `LinkedPremises` thermal-zone, space, or section IDrefs | Resolve every served premise; include all zones on shared existing loops | Comma-separated model names | Incomplete linked premises can make replacement unsafe |
| `standards_template` | No direct field | Baseline/retrofit modeling policy | None | Workflow input |

## Usage

1. Resolve all premises served by the replacement system.
2. Ensure the target includes every zone on affected shared loops.
3. Run this measure, then use focused modifiers for audited efficiency values.

## Limitations

Existing plant loops are deliberately preserved. A failed creation after removal is reported but OpenStudio measures are not transactional; use workflow checkpoints for production replacement studies.
