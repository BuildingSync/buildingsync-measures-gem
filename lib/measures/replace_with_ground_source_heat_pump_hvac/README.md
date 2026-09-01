# Replace HVAC with Ground-Source Heat Pumps

Replaces complete selected-zone HVAC with ground-coupled water-to-air heat pumps.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/HeatPump` with `HeatPump/CoolingSourceID/@IDref` joined to `CoolingSources/CoolingSource/CoolingSourceType/DX`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref` resolves to `Plants/CondenserPlants/CondenserPlant/GroundSource/GroundSourceType = "Open loop ground water"` or `"Closed loop ground source"`; associated `Delivery/DeliveryType/ZoneEquipment` serves the same premises | Require proposed ground-source condenser evidence and resolved heat-pump/source/delivery links | Exact enum plus IDREF relationships | High for ground coupling; medium-high for full terminal topology |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Ground Source Heat Pump"` | Use only if proposed L200 ground-source records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status or condenser IDs are unresolved, GroundSourceType is `Other`/`Unknown`, or water-to-air zone terminals are not established | Distinguish GSHP terminals from central ground-coupled plants and confirm complete removal scope | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Proposed terminal/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Include all zones on affected shared air loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved. New ground infrastructure uses standards defaults; detailed bore-field design remains outside this measure.
