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
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/FanBased/FanBasedDistributionType/FanCoil/FanCoilType = "Fan coil 4 pipe"` and `HVACPipeConfiguration = "4 pipe"`; `HeatingSourceID/@IDref` resolves to `HeatingMedium = "Hot water"`; `CoolingSourceID/@IDref` resolves to `CoolingMedium = "Chilled water"` | Require proposed status, explicit fan-coil type, and both hydronic circuits | Exact enums plus IDREF relationships | High when all records resolve |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Four Pipe Fan Coil Unit"` | Use only if proposed L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status, fan-coil type, pipe configuration, either source link, or plant resolution is missing/unknown | Confirm two independent water coils and full existing shared-system scope | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | Proposed delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete served scope; include all zones on affected shared loops | Comma-separated names | Incomplete shared-loop scope is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audited data |

## Usage

1. Resolve all replacement-system premises.
2. Confirm complete scope for shared air loops.
3. Run the replacement, then set audited plant capacities, efficiencies, and temperatures with focused modifiers.

## Limitations

Pre-existing plant loops are preserved to avoid deleting shared infrastructure; they may become orphaned. New plants may be created rather than merged with existing loops. Workflow checkpoints are recommended because model edits are not transactional.
