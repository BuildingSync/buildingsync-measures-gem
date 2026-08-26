# Replace HVAC with Ground-Source Heat Pumps

Replaces complete selected-zone HVAC with ground-coupled water-to-air heat pumps.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed ground-source heat-pump sources and ground heat-exchanger links | Consumer confirms ground-coupled topology | Relationship mapping | Scenario context identifies proposed equipment |
| `target_zone_names` | Proposed-system `LinkedPremises` IDrefs | Include all zones on affected shared air loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved. New ground infrastructure uses standards defaults; detailed bore-field design remains outside this measure.
