# Create Chilled-Beam HVAC

Adds four-pipe chilled-beam terminals, a dedicated primary outdoor-air loop, and new supporting hot- and chilled-water plants to unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Supporting plant construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; delivery/zone-equipment records identifying chilled beams; linked DOAS and hydronic plants | Require beam terminals plus primary ventilation and chilled-water evidence | Relationship/enum mapping | High with explicit chilled-beam type; medium when inferred from linked equipment |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve beam-served premises to exact model thermal zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

This measure creates four-pipe beams because that terminal type has explicit heating and cooling plant connections in OpenStudio 3.10. Supporting plants are first generated from standards fan-coil infrastructure; the temporary fan coils are removed. The primary-air loop contains outdoor-air intake and a fan but no audited conditioning coils, heat recovery, or humidity controls. Apply those details with focused modifiers or downstream workflow steps.
