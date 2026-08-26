# Create Low-Temperature Radiant HVAC

Adds hydronic low-temperature radiant heating and cooling plus supporting plants to unserved zones with modeled surfaces.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Radiant system construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; delivery/zone-equipment records identifying radiant slabs, floors, or ceilings; linked hydronic plants | Require explicit radiant delivery or credible surface-plus-plant evidence | Relationship/enum mapping | High with explicit radiant type; medium when inferred |
| `target_zone_names` | HVAC `LinkedPremises` zone/space/section IDrefs | Resolve radiant-served premises to exact model thermal zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Zones must contain modeled surfaces. The standards implementation modifies constructions to support internal-source radiant surfaces and selects the actual surfaces. BuildingSync often does not identify surface assignments, so geometry-specific mapping remains uncertain. Plant temperatures and efficiencies remain separate focused modifications.
