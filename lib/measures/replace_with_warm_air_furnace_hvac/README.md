# Replace HVAC with Warm-Air Furnace

Removes HVAC dedicated to explicitly selected zones and installs the `Forced Air Furnace` topology.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones to replace | Required; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | Recommended `PrincipalHVACSystemType`; heating-source `Furnace`; distribution-system type | Require the proposed system to be warm-air furnace heat | Relationship/enum mapping | Medium; confirm distribution evidence rather than relying on fuel alone |
| `target_zone_names` | Recommended HVAC `LinkedPremises` zone/space/section IDrefs | Resolve complete replacement scope to exact model thermal-zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Partial removal of shared air loops is rejected; expand the target scope to every served zone. Existing plant loops are preserved. Model edits are not transactional, so retain an input-model copy before replacement.
