# Replace HVAC with Water-Loop Heat Pumps

Replaces complete selected-zone HVAC with water-to-air heat pumps and supporting loop infrastructure.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred candidate) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/HeatPump` with `HeatPump/CoolingSourceID/@IDref` joined to `CoolingSources/CoolingSource/CoolingSourceType/DX`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref` resolves to `Plants/CondenserPlants/CondenserPlant/WaterCooled`; associated `Delivery/DeliveryType/ZoneEquipment` serves the same premises | Use proposed relationships to identify heat-pump terminals on a shared water-cooled loop | Element presence plus IDREF relationships | Medium: no direct water-loop heat-pump L200 enum exists |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Water Loop Heat Pump"` | Use only if proposed L200 records are unavailable; still verify loop type | Exact enum | Medium |
| MANUAL CHECK | Always confirm water-to-air terminals, shared tempered loop, non-ground-source condenser, proposed status, resolved IDREFs, and complete existing shared-system scope | The L200 schema cannot directly establish the entire topology | Manual topology review | Always required |
| `target_zone_names` | Proposed terminal/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Include all zones on affected shared air loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved; new infrastructure may be added. Checkpoint before replacement and apply audit COPs afterward.
