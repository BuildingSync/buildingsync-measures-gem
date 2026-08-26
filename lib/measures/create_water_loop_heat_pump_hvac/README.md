# Create Water-Loop Heat Pump HVAC

Adds one water-to-air heat pump per unserved zone plus shared water-loop heat-rejection and heat-addition infrastructure.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; water-source heat-pump heating/cooling sources; common condenser-water loop | Require water-to-air units connected to a shared tempered loop | Relationship/enum mapping | High when loop and unit links are explicit |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve all terminal-served premises to exact zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Plant topology may be newly created rather than merged. Apply audited heat-pump COPs and plant properties with focused modifiers.
