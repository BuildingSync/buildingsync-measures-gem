# Replace HVAC with Packaged Rooftop Heat Pump

Replaces systems dedicated to selected zones with packaged single-zone rooftop heat pumps.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed `PrincipalHVACSystemType`; fallback packaged DX heat-pump evidence | Consumer selects PSZ-HP replacement topology | Enum mapping | Scenario context distinguishes existing/proposed systems |
| `target_zone_names` | Proposed-system `LinkedPremises` IDrefs | Resolve complete served scope and include all zones on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

## Usage and limitations

Resolve complete scope, checkpoint the model, and run the measure. Existing plant loops are preserved. Apply audited controls and COPs afterward. OpenStudio edits are not transactional.
