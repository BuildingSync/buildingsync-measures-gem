# Replace HVAC with PTHP

Removes HVAC dedicated to selected zones and installs packaged terminal heat pumps while preserving unrelated systems and plant loops.

## Use this measure when

- A retrofit or comparison case replaces complete serving systems with PTHPs.
- Every zone on an affected shared air loop is selected.

Do not use it for efficiency-only changes.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Comma-separated exact zones whose HVAC will be replaced | Required |
| `standards_template` | Template used for replacement creation | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed/retrofit `PrincipalHVACSystemType`; fallback terminal heat-pump DX evidence | Consumer selects this measure only when replacement topology is PTHP | Enum mapping only | Scenario context identifies existing versus proposed systems |
| `target_zone_names` | Replacement system `LinkedPremises` thermal-zone, space, or section IDrefs | Resolve every served premise and include all zones on shared existing loops | Comma-separated names | Incomplete scope is rejected when detectable |
| `standards_template` | No direct field | Workflow policy | None | Not an audited property |

## Usage

1. Resolve every premise served by the replacement system.
2. Confirm complete shared-loop scope.
3. Run this measure, then apply audited efficiencies with focused modifiers.

## Limitations

Existing plant loops are preserved. OpenStudio model edits are not transactional, so production workflows should checkpoint the model before replacement.
