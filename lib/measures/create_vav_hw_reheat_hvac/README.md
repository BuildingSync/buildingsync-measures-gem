# Create VAV with Hot Water Reheat

Adds built-up central VAV with hot-water terminal reheat to unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; central VAV delivery; built-up chilled-water cooling; hot-water terminal reheat | Require built-up VAV plus hydronic cooling/reheat evidence | Relationship/enum mapping | Medium when packaged versus built-up is not explicit |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve complete served scope to exact names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. Plant infrastructure may be created; apply audited controls, temperatures, capacities, and efficiencies with focused modifiers.
