# Create Dedicated Outdoor Air System

Adds a DOAS air loop to selected unserved zones. The loop, outdoor-air system, and fan are constructed directly because the pinned standards API did not create a DOAS loop in minimal models. No outdoor-air heating/cooling coils or separate zone sensible-conditioning system are added.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; dedicated outdoor-air or 100% outdoor-air central delivery; heat-recovery evidence | Require explicit DOAS or dedicated ventilation evidence | Relationship/enum mapping | Medium-high when dedicated OA is explicit |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve complete served scope to exact model names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. Configure SAT, economizer, and heat recovery afterward with focused modifiers. Zone sensible loads may require separate terminals.
