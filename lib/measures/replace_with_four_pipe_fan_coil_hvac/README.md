# Replace HVAC with Four-Pipe Fan Coils

Replaces HVAC dedicated to selected zones with four-pipe fan coils and required new plant infrastructure.

## Use this measure when

- A retrofit replaces the complete zone-serving system with four-pipe fan coils.
- Every zone on an affected shared air loop is selected.

Do not use it for plant-only or efficiency-only changes.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Comma-separated exact zones whose HVAC will be replaced | Required |
| `standards_template` | Template used for replacement creation | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection | Proposed/retrofit `PrincipalHVACSystemType`; fallback four-pipe fan-coil delivery plus heating/cooling plant links | Consumer selects only when replacement topology includes both water coils | Enum/relationship mapping | Scenario context distinguishes existing and proposed systems |
| `target_zone_names` | Replacement system `LinkedPremises` IDrefs | Resolve complete served scope; include all zones on affected shared loops | Comma-separated names | Incomplete shared-loop scope is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audited data |

## Usage

1. Resolve all replacement-system premises.
2. Confirm complete scope for shared air loops.
3. Run the replacement, then set audited plant capacities, efficiencies, and temperatures with focused modifiers.

## Limitations

Pre-existing plant loops are preserved to avoid deleting shared infrastructure; they may become orphaned. New plants may be created rather than merged with existing loops. Workflow checkpoints are recommended because model edits are not transactional.
