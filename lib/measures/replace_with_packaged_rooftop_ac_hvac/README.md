# Replace HVAC with Packaged Rooftop AC

Replaces systems dedicated to selected zones with packaged single-zone rooftop air conditioners.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed `PrincipalHVACSystemType`; fallback packaged DX AC and single-zone delivery evidence | Consumer selects PSZ-AC replacement topology | Enum mapping | Scenario context distinguishes existing/proposed systems |
| `target_zone_names` | Proposed-system `LinkedPremises` IDrefs | Resolve complete served scope and include all zones on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

## Usage and limitations

Resolve complete serving scope, checkpoint the model, and run the measure. Existing plant loops are preserved. Apply audited controls and efficiencies with focused modifiers. OpenStudio edits are not transactional.
