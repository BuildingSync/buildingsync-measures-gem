# Create VAV with Electric Reheat

Adds built-up central VAV with parallel fan-powered electric-reheat terminals to unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; central VAV delivery; built-up chilled-water cooling; fan-powered electric-reheat terminals | Require built-up VAV and electric terminal evidence | Relationship/enum mapping | Medium if fan arrangement is not explicit |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve complete served scope to exact names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. Apply audited controls, plant properties, and terminal efficiencies with focused modifiers.
