# Replace HVAC with Packaged Rooftop VAV and Hot Water Reheat

Replaces complete zone-serving HVAC with packaged multizone VAV and hot-water reheat.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed `PrincipalHVACSystemType`; VAV delivery, packaged DX source, and hot-water terminal reheat | Consumer selects the exact proposed topology | Relationship/enum mapping | Scenario context identifies proposed versus existing systems |
| `target_zone_names` | Proposed-system `LinkedPremises` IDrefs | Include every zone on affected shared loops | Join exact model names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plant loops are preserved and new hot-water infrastructure may be created. Checkpoint the model because edits are not transactional; apply audit values with focused modifiers afterward.
