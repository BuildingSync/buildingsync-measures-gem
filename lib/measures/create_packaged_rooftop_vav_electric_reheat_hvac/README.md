# Create Packaged Rooftop VAV with Electric Reheat

Adds packaged multizone VAV with parallel fan-powered electric-reheat terminals to selected unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; central-air VAV delivery; packaged DX cooling; fan-powered terminal and electric reheat evidence | Require packaged multizone VAV with electric terminal reheat | Relationship/enum mapping | Medium when terminal fan arrangement is not explicit |
| `target_zone_names` | HVAC `LinkedPremises` thermal-zone, space, or section IDrefs | Resolve complete served scope to exact model names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. This topology does not request a hydronic reheat plant. Apply audited controls and efficiencies with focused modifiers.
