# Four-Pipe Fan-Coil HVAC

Creates four-pipe fan coils and supporting plants or replaces HVAC dedicated to selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/FanBased/FanBasedDistributionType/FanCoil/FanCoilType = "Fan coil 4 pipe"`; `HVACPipeConfiguration = "4 pipe"`; `Delivery/HeatingSourceID/@IDref` resolves to `HeatingMedium = "Hot water"`; `Delivery/CoolingSourceID/@IDref` resolves to `CoolingMedium = "Chilled water"` | Active/baseline records select `create`; matching proposed records with `@Status = "Proposed"` select `replace` | High when all exact values and source joins resolve |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Four Pipe Fan Coil Unit"` | Use only when L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status, fan-coil type, pipe configuration, either source link, or plant resolution is missing/unknown | Confirm complete four-pipe hydronic topology and replacement scope | Required if any condition applies |
| `target_zone_names` | `Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve exact zones; include complete shared-loop scope for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Replacement removes target-zone equipment and dedicated air loops but deliberately preserves existing plant loops.