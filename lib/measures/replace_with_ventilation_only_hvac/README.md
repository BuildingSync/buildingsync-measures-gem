# Replace HVAC with Ventilation-Only Systems

Removes complete zone-serving HVAC and installs ventilation-only air delivery.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed ventilation system, central-air delivery, and absence of heating/cooling source links | Consumer confirms the proposed topology is ventilation-only | Relationship mapping | Low-medium; scenario intent is essential |
| `target_zone_names` | Proposed-system `LinkedPremises` IDrefs | Include every zone on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved. The replacement supplies no space conditioning; checkpoint the model before this non-transactional edit.
