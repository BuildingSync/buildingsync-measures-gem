# Create Ground-Source Heat Pump HVAC

Adds ground-coupled water-to-air heat pumps and supporting ground-loop infrastructure to unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/HeatPump` with `HeatPump/CoolingSourceID/@IDref` joined to `CoolingSources/CoolingSource/CoolingSourceType/DX`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref` resolves to `HVACSystem/Plants/CondenserPlants/CondenserPlant/GroundSource/GroundSourceType = "Open loop ground water"` or `"Closed loop ground source"`; associated `Delivery/DeliveryType/ZoneEquipment` serves the same premises | Require explicit ground-source condenser evidence and resolved heat-pump/source/delivery links | Exact enum plus IDREF relationships | High for ground coupling; medium-high for full terminal topology |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Ground Source Heat Pump"` | Use only if L200 ground-source records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | GroundSourceType is `Other`/`Unknown`, condenser IDs do not resolve, or the records do not establish water-to-air zone heat pumps | Distinguish GSHP terminals from central ground-coupled chillers and water-loop heat pumps | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Terminal/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve terminal-served premises to exact zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Ground-loop geometry and soil properties use standards defaults and are not inferred from BuildingSync. Apply audited COPs with the focused efficiency modifier.
