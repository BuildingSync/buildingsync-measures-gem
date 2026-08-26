# Create Ground-Source Heat Pump HVAC

Adds ground-coupled water-to-air heat pumps and supporting ground-loop infrastructure to unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; ground-source heat-pump sources; ground heat-exchanger or ground-loop evidence | Require ground coupling rather than tower/boiler tempered loop | Relationship/enum mapping | Medium-high when ground-loop details exist |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve terminal-served premises to exact zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Ground-loop geometry and soil properties use standards defaults and are not inferred from BuildingSync. Apply audited COPs with the focused efficiency modifier.
