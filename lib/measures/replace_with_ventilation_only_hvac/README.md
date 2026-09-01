# Replace HVAC with Ventilation-Only Systems

Removes complete zone-serving HVAC and installs ventilation-only air delivery.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Supply only"` + `HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/NoHeating` present + `CoolingSources/CoolingSource/CoolingSourceType/NoCooling` present + `Deliveries/Delivery/DeliveryType/CentralAirDistribution` present | Require positive proposed no-heating and no-cooling elements; absent records do not prove no conditioning | Exact enum/element conjunction | High only when all facts are explicit |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Ventilation Only"` | Use only if proposed L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status is unclear, sources are merely absent, ventilation type is not `Supply only`, or ventilation/delivery records cannot be joined | Confirm no thermal conditioning is intended and include every zone on existing shared loops | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Proposed ventilation/delivery/HVAC `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Include every zone on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved. The replacement supplies no space conditioning; checkpoint the model before this non-transactional edit.
