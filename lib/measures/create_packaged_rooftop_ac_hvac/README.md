# Create Packaged Rooftop AC HVAC

Adds packaged single-zone rooftop air conditioners to selected unserved zones.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zone names; blank selects all | Optional; comma-separated |
| `standards_template` | openstudio-standards construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; fallback packaged DX `CoolingSourceType/DX/DXSystemType` plus single-zone central-air delivery | Require packaged rooftop AC evidence without heat-pump heating | Enum mapping | High for explicit L100; medium for combined L200 evidence |
| `target_zone_names` | HVAC `LinkedPremises` thermal-zone, space, or section IDrefs | Resolve every linked premise to exact model zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

## Usage and limitations

Use only on unserved zones; use `replace_with_packaged_rooftop_ac_hvac` for retrofit replacement. The measure creates topology and default performance. Apply audited SAT, economizer, and equipment efficiencies afterward with focused modifiers.
