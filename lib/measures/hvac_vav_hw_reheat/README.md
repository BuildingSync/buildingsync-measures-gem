# VAV with Hot-Water Reheat HVAC

Creates built-up multizone VAV with chilled-water cooling and hot-water terminal reheat, or replaces dedicated HVAC.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"`; `CoolingPlantID/@IDref` resolves to `HVACSystem/Plants/CoolingPlants/CoolingPlant/Chiller` with `CoolingMedium = "Chilled water"`; `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box not fan powered with reheat"`; `ReheatSource = "Heating plant"`; `ReheatPlantID/@IDref` resolves to `Plants/HeatingPlants/HeatingPlant/Boiler/BoilerType = "Hot water"` | Active/baseline facts select `create`; same proposed facts with `@Status = "Proposed"` select `replace` | High when both plant links and terminal evidence resolve |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "VAV with Hot Water Reheat"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status, `CoolingPlantID`, `ReheatPlantID`, terminal/reheat evidence, or packaged-versus-built-up distinction is unresolved; or DX cooling appears instead of a chiller link | Confirm full built-up topology and replacement scope | Required if any condition applies |
| `target_zone_names` | `Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete multizone scope; include every zone on shared loops for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Replacement preserves pre-existing plant loops even when they become orphaned.