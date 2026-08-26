# Replace HVAC with Water-Loop Heat Pumps

Replaces complete selected-zone HVAC with water-to-air heat pumps and supporting loop infrastructure.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed water-source heat-pump sources and common water-loop links | Consumer confirms water-loop, not ground-loop, topology | Relationship mapping | Scenario context identifies proposed equipment |
| `target_zone_names` | Proposed-system `LinkedPremises` IDrefs | Include all zones on affected shared air loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved; new infrastructure may be added. Checkpoint before replacement and apply audit COPs afterward.
