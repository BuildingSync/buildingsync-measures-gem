# VAV with Electric Reheat HVAC

Creates built-up multizone VAV with chilled-water cooling and fan-powered electric reheat, or replaces dedicated HVAC.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"`; `CoolingPlantID/@IDref` resolves to `HVACSystem/Plants/CoolingPlants/CoolingPlant/Chiller` with `CoolingMedium = "Chilled water"`; `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box fan powered with reheat"`; `ReheatSource = "Local electric resistance"` | Active/baseline facts select `create`; same proposed facts with `@Status = "Proposed"` select `replace` | High when chiller, terminal, and reheat evidence agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "VAV with Electric Reheat"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status, `CoolingPlantID`, fan-powered terminal, electric reheat, or packaged-versus-built-up distinction is unresolved; or DX cooling appears instead of a chiller link | Confirm full topology and replacement scope | Required if any condition applies |
| `target_zone_names` | `Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all zones; include complete shared-loop scope for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Creation requires unserved zones. Replacement rejects partial shared-air-loop removal and preserves plants.