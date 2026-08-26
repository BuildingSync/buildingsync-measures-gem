# Replace HVAC with a Dedicated Outdoor Air System

Replaces complete zone-serving HVAC with a directly constructed DOAS air loop while preserving existing plants. The replacement contains an outdoor-air system and fan but no outdoor-air heating/cooling coils or separate zone sensible-conditioning equipment.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed DOAS or dedicated 100% outdoor-air delivery and optional heat recovery | Consumer confirms exact proposed topology | Relationship/enum mapping | Medium-high when DOAS is explicit |
| `target_zone_names` | Proposed-system `LinkedPremises` IDrefs | Include every zone on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

This replacement does not add separate zone sensible conditioning. Checkpoint before replacement and apply audited controls and heat-recovery properties afterward.
