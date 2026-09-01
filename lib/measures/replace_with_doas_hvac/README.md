# Replace HVAC with a Dedicated Outdoor Air System

Replaces complete zone-serving HVAC with a directly constructed DOAS air loop while preserving existing plants. The replacement contains an outdoor-air system and fan but no outdoor-air heating/cooling coils or separate zone sensible-conditioning equipment.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Dedicated outdoor air system"`; corroborate with proposed `HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution` and matching `LinkedPremises` | Require exact proposed DOAS enum and dedicated served scope | Exact enum plus premise/delivery relationships | High for ventilation type; medium for air-loop reconstruction |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Dedicated Outdoor Air System"` | Use only if the proposed L200 ventilation record is unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status is unclear, VentilationType is another enum, or the record does not establish a dedicated outdoor-air air loop | Confirm conditioning, heat recovery, exact served zones, and full existing shared-loop scope | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Proposed `OtherHVACSystem`, delivery, or HVAC-system `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Include every zone on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

This replacement does not add separate zone sensible conditioning. Checkpoint before replacement and apply audited controls and heat-recovery properties afterward.
