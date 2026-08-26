# Create VRF HVAC

Adds variable-refrigerant-flow outdoor equipment and one terminal per selected unserved zone.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; cooling/heating sources identifying variable-refrigerant-flow or variable-refrigerant-volume equipment; linked terminal systems | Require explicit VRF/VRV outdoor-unit and terminal evidence | Relationship/enum mapping | High with explicit system type; low if inferred only from heat-pump fuel/source |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs and terminal links | Resolve all terminal-served premises to exact model thermal-zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

The standards template determines heat-recovery configuration, capacities, curves, and supplemental heat. Apply audited VRF COPs with the focused efficiency modifier.
