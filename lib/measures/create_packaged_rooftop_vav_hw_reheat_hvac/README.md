# Create Packaged Rooftop VAV with Hot Water Reheat

Adds packaged multizone VAV with hot-water terminal reheat to selected unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"` + `CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box not fan powered with reheat"` + `ReheatSource = "Heating plant"`; `ReheatPlantID/@IDref` must resolve to `HVACSystem/Plants/HeatingPlants/HeatingPlant/Boiler/BoilerType = "Hot water"` | Require packaged DX, multizone VAV, and hydronic terminal reheat evidence | Exact enums plus IDREF relationships | High when all records resolve |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop VAV with Hot Water Reheat"` | Use only if L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | DX source, VAV terminal type, reheat source, or hot-water plant link is missing; or source records cannot distinguish packaged from built-up cooling | Confirm the complete packaged multizone topology | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve the complete served multizone scope to exact model names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. New hot-water plant infrastructure may be created. Apply audited loop controls, boiler properties, temperatures, and efficiencies with focused modifiers.
