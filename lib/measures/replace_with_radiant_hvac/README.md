# Replace HVAC with Low-Temperature Radiant

Replaces HVAC dedicated to selected zones with hydronic low-temperature radiant heating and cooling.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones to replace | Required; comma-separated |
| `standards_template` | Radiant system construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | Recommended `PrincipalHVACSystemType`; proposed radiant slab/floor/ceiling delivery; linked hydronic plants | Require explicit proposed radiant topology or credible surface-plus-plant evidence | Relationship/enum mapping | High with explicit radiant type; medium when inferred |
| `target_zone_names` | Recommended HVAC `LinkedPremises` zone/space/section IDrefs | Resolve complete replacement scope to exact model thermal zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Partial shared-air-loop removal is rejected, and pre-existing plants are preserved. Zones must contain modeled surfaces. The standards implementation alters constructions and assigns radiant surfaces; BuildingSync surface mapping is frequently incomplete. Model edits are not transactional.
