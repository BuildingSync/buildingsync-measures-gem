# Replace HVAC with VAV and Hot Water Reheat

Replaces complete serving systems with built-up VAV and hot-water reheat.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed `PrincipalHVACSystemType`; VAV delivery, chilled-water cooling, hot-water reheat | Consumer selects exact proposed topology | Relationship mapping | Scenario context distinguishes existing/proposed systems |
| `target_zone_names` | Proposed-system `LinkedPremises` IDrefs | Include every zone on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved and new plants may be created. Checkpoint before replacement and apply audit values afterward.
