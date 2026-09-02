# PTHP HVAC

Creates packaged terminal heat pumps in unserved zones or replaces HVAC dedicated to explicitly selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged terminal heat pump (PTHP)"`; `HeatingSources/HeatingSource/HeatingSourceType/HeatPump/HeatPumpType = "Packaged Terminal"`; associated `Deliveries/Delivery/DeliveryType/ZoneEquipment`; verify `CoolingSourceID/@IDref` and `HeatingSourceID/@IDref` joins | Active/baseline facts select `create`; the same facts on `HVACSystem[@Status = "Proposed"]` select `replace` | High when both exact enums and all joins agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Terminal Heat Pump"` | Use only if L200 is unavailable and noncontradictory; proposed scope is mandatory for `replace` | Medium |
| MANUAL CHECK | Either enum or proposed status is absent, cooling/heating/delivery cannot be joined, or central-air delivery is indicated | Confirm PTHP topology and complete replacement scope | Required if any condition applies |
| `target_zone_names` | HVAC/component `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` under `LinkedPremises` | Resolve all served premises; include all zones on shared existing loops for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Creation requires unserved zones. Replacement preserves plants and rejects partial shared-air-loop removal before mutation.