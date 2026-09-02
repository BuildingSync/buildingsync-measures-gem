# Ground-Source Heat-Pump HVAC

Creates ground-source water-to-air heat pumps or replaces HVAC dedicated to selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/HeatPump`; `HeatPump/CoolingSourceID/@IDref` joins to `CoolingSources/CoolingSource/CoolingSourceType/DX`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref` resolves to `HVACSystem/Plants/CondenserPlants/CondenserPlant/GroundSource/GroundSourceType = "Open loop ground water"` or `"Closed loop ground source"`; associated `Delivery/DeliveryType/ZoneEquipment` serves the same premises | Active/baseline facts select `create`; same proposed facts with `@Status = "Proposed"` select `replace` | High when ground source, water-to-air terminals, and IDREFs all resolve |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Ground Source Heat Pump"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status or condenser IDs are unresolved, `GroundSourceType` is `Other`/`Unknown`, or records do not establish water-to-air zone heat pumps | Confirm ground-source topology and complete replacement scope | Required if any condition applies |
| `target_zone_names` | Terminal/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve every served zone and complete shared scope for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Replacement preserves pre-existing plant loops and rejects partial shared-air-loop removal.