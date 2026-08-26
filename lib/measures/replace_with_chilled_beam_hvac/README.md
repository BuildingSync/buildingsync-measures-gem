# Replace HVAC with Chilled Beams

Replaces HVAC dedicated to selected zones with four-pipe chilled beams, a primary outdoor-air loop, and new supporting plants.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones to replace | Required; comma-separated |
| `standards_template` | Supporting plant construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | Recommended `PrincipalHVACSystemType`; proposed chilled-beam terminals; linked DOAS and hydronic plants | Require explicit proposed beam and primary-air topology | Relationship/enum mapping | High with explicit chilled-beam type; medium when inferred |
| `target_zone_names` | Recommended HVAC `LinkedPremises` zone/space/section IDrefs | Resolve the complete affected air-loop service scope | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Partial shared-air-loop removal is rejected. Existing plant loops are preserved rather than inferred as reusable; new beam plants are created. The primary-air loop has outdoor-air intake and a fan but no audited conditioning coils, heat recovery, or humidity controls. Model edits are not transactional.
