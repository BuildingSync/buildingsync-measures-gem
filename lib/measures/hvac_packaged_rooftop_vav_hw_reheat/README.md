# Packaged Rooftop VAV with Hot-Water Reheat HVAC

Creates packaged multizone VAV with hot-water terminal reheat or replaces dedicated HVAC for selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"`; `CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"`; `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box not fan powered with reheat"`; `ReheatSource = "Heating plant"`; `ReheatPlantID/@IDref` resolves to `HVACSystem/Plants/HeatingPlants/HeatingPlant/Boiler/BoilerType = "Hot water"` | Active/baseline facts select `create`; require the same facts on `HVACSystem[@Status = "Proposed"]` for `replace` | High when all records and IDREFs resolve |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop VAV with Hot Water Reheat"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status, DX source, VAV terminal, reheat source, or hot-water plant link is missing; or packaged versus built-up cooling is unresolved | Confirm the complete topology and replacement scope | Required if any component cannot be mapped directly |
| `target_zone_names` | `Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete multizone scope; `replace` requires every zone on affected shared loops | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Replacement preserves existing plants. Use focused modifiers for audited loop controls, boiler properties, temperatures, and efficiencies.