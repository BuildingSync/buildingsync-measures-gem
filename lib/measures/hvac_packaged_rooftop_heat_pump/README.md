# Packaged Rooftop Heat-Pump HVAC

Creates single-zone packaged rooftop heat pumps or replaces HVAC dedicated to selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary heat pump"`; `HeatingSources/HeatingSource/HeatingSourceType/HeatPump/HeatPumpType = "Packaged Unitary"`; `ZoningSystemType = "Single zone"`; `Deliveries/Delivery/DeliveryType/CentralAirDistribution/AirDeliveryType = "Central fan"` | Active/baseline facts select `create`; the same facts on `HVACSystem[@Status = "Proposed"]` select `replace` | High when all exact values and relationships agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop Heat Pump"` | Use only when L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status is unclear, packaged-unitary cooling and heating are not linked, zoning/delivery is missing, or furnace heating is also indicated | Distinguish PSZ-HP from PSZ-AC and verify replacement scope | Required if any condition applies |
| `target_zone_names` | HVAC/source/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all premises and complete shared-loop scope | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Creation requires unserved zones. Replacement preserves plants and rejects partial shared-loop removal.