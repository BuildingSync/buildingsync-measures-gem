# Create Ventilation-Only HVAC

Adds outdoor-air delivery without space heating or cooling to unserved zones. The air loop, outdoor-air system, and fan are constructed directly because openstudio-standards 0.8.2 does not recognize a `Ventilation Only` system key.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; `DeliveryType/CentralAirDistribution`; ventilation rate and outdoor-air evidence | Select only when the modeled system supplies ventilation without thermal conditioning | Relationship/enum mapping | Low-medium; BuildingSync may not explicitly distinguish ventilation-only air loops |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve complete served scope to exact model names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. This measure does not provide zone heating or cooling; separate systems may be needed by the workflow.
