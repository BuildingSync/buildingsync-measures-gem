# Replace HVAC with Packaged Rooftop VAV and Hot Water Reheat

Replaces complete zone-serving HVAC with packaged multizone VAV and hot-water reheat.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"` + `CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box not fan powered with reheat"` + `ReheatSource = "Heating plant"`; `ReheatPlantID/@IDref` resolves to `Plants/HeatingPlants/HeatingPlant/Boiler/BoilerType = "Hot water"` | Require the complete proposed packaged multizone and hydronic-reheat topology | Exact enums plus IDREF relationships | High when all records resolve |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop VAV with Hot Water Reheat"` | Use only if proposed L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status, packaged DX, VAV terminal, reheat source, or hot-water plant link is missing; or packaged versus built-up cooling is unresolved | Confirm exact proposed topology and complete existing shared-loop scope | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | Proposed delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Include every zone on affected shared loops | Join exact model names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plant loops are preserved and new hot-water infrastructure may be created. Checkpoint the model because edits are not transactional; apply audit values with focused modifiers afterward.
