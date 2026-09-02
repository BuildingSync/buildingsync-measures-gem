# Water-Loop Heat-Pump HVAC

Creates water-to-air heat pumps on a shared tempered loop or replaces dedicated HVAC for selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred candidate) | `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/HeatPump`; `HeatPump/CoolingSourceID/@IDref` joins to `CoolingSources/CoolingSource/CoolingSourceType/DX`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref` resolves to `HVACSystem/Plants/CondenserPlants/CondenserPlant/WaterCooled`; associated `Deliveries/Delivery/DeliveryType/ZoneEquipment` serves the same premises | Active/baseline facts suggest `create`; equivalent facts on `HVACSystem[@Status = "Proposed"]` suggest `replace` | No direct L200 water-loop HP enum; manual confirmation is always required |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Water Loop Heat Pump"` | Weak fallback only; never override contradictory L200 facts | Medium-low |
| MANUAL CHECK | Confirm water-to-air terminals on one shared tempered loop, a non-ground-source condenser plant, resolved source/terminal IDREFs, proposed status for `replace`, and complete existing shared-system scope | Manual topology review | Always required |
| `target_zone_names` | Terminal/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all served zones and complete shared scope | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Replacement preserves existing plant loops, including loops orphaned by removed zone equipment.