# Create Packaged Rooftop VAV with Hot Water Reheat

Adds packaged multizone VAV with hot-water terminal reheat to selected unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; central-air VAV delivery; packaged DX cooling; terminal hot-water reheat | Require packaged multizone VAV and hydronic reheat evidence | Relationship/enum mapping | High if explicit; medium when inferred across delivery and source records |
| `target_zone_names` | HVAC `LinkedPremises` thermal-zone, space, or section IDrefs | Resolve the complete served multizone scope to exact model names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. New hot-water plant infrastructure may be created. Apply audited loop controls, boiler properties, temperatures, and efficiencies with focused modifiers.
