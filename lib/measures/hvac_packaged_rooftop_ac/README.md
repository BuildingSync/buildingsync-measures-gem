# Packaged Rooftop Air-Conditioner HVAC

Creates single-zone packaged rooftop air conditioners or replaces HVAC dedicated to selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"`; `ZoningSystemType = "Single zone"`; `Deliveries/Delivery/DeliveryType/CentralAirDistribution/AirDeliveryType = "Central fan"`; heating resolves to `HeatingSources/HeatingSource/HeatingSourceType/Furnace/FurnaceType = "Warm air"`, not `HeatPump` | Use active/baseline facts for `create`; require the same facts on `HVACSystem[@Status = "Proposed"]` for `replace` | High when source, zoning, delivery, and furnace evidence agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop Air Conditioner"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status, zoning, central-air delivery, or heating source is absent/ambiguous, or heat-pump heating is present | Distinguish PSZ-AC from PSZ-HP and confirm complete replacement scope | Required if any condition applies |
| `target_zone_names` | HVAC/source/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all IDs; include every zone on affected shared loops for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Creation requires unserved zones. Replacement preserves plant loops and rejects partial shared-loop removal.