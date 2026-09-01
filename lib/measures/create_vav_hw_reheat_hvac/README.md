# Create VAV with Hot Water Reheat

Adds built-up central VAV with hot-water terminal reheat to unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"` + `CoolingSources/CoolingSource/CoolingSourceType/CoolingPlantID/@IDref` resolving to `HVACSystem/Plants/CoolingPlants/CoolingPlant/Chiller` + `CoolingSource/CoolingMedium = "Chilled water"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box not fan powered with reheat"` + `ReheatSource = "Heating plant"`; `ReheatPlantID/@IDref` resolves to `HeatingPlant/Boiler/BoilerType = "Hot water"` | Require a central chiller, multizone VAV delivery, and hot-water terminal reheat | Exact enums/elements plus IDREF relationships | High when all records resolve |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "VAV with Hot Water Reheat"` | Use only if L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | CoolingPlantID or ReheatPlantID is unresolved, terminal/reheat type is missing, or DX cooling is present instead of a chiller link | Distinguish built-up VAV from packaged rooftop VAV | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete served scope to exact names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. Plant infrastructure may be created; apply audited controls, temperatures, capacities, and efficiencies with focused modifiers.
