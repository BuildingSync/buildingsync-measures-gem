# Replace HVAC with VRF

Removes HVAC dedicated to explicitly selected zones and installs variable-refrigerant-flow outdoor equipment and terminals.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones to replace | Required; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | Recommended `PrincipalHVACSystemType`; proposed cooling/heating sources identifying VRF/VRV; linked terminal systems | Require explicit proposed VRF outdoor-unit and terminal evidence | Relationship/enum mapping | High with explicit system type; low if inferred only from heat-pump source |
| `target_zone_names` | Recommended HVAC `LinkedPremises` zone/space/section IDrefs and terminal links | Resolve the complete outdoor-unit service scope to exact model thermal-zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Partial removal of shared air loops or shared VRF outdoor units is rejected; include every zone served by each affected system. Existing plant loops are preserved. Model edits are not transactional, so retain an input-model copy.
