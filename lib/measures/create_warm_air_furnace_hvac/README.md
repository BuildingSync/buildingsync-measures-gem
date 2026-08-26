# Create Warm-Air Furnace HVAC

Adds warm-air furnace heating to selected unserved zones using the `Forced Air Furnace` topology.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; heating-source `Furnace`; distribution-system type and served premises | Require furnace heating delivered by warm air rather than hydronic or local-only heat | Relationship/enum mapping | Medium; audit records may identify a furnace without enough distribution detail |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve all furnace-served premises to exact model thermal-zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

The standards topology may use air loops, zone unit heaters, or both depending on template and model context. Apply audited furnace efficiency and air-loop controls with the focused modifier measures.
