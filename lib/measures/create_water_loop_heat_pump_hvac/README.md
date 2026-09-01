# Create Water-Loop Heat Pump HVAC

Adds one water-to-air heat pump per unserved zone plus shared water-loop heat-rejection and heat-addition infrastructure.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred candidate) | `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/HeatPump` with `HeatPump/CoolingSourceID/@IDref` joined to `CoolingSources/CoolingSource/CoolingSourceType/DX`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref` resolves to `HVACSystem/Plants/CondenserPlants/CondenserPlant/WaterCooled`; associated `Delivery/DeliveryType/ZoneEquipment` serves the same premises | Use the relationships to identify heat-pump terminals on a shared water-cooled condenser loop | Element presence plus IDREF relationships | Medium: the XSD has no water-source/water-loop heat-pump enum |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Water Loop Heat Pump"` | Use only if L200 records are unavailable; still verify loop type before modeling | Exact enum | Medium |
| MANUAL CHECK | Always confirm the units are water-to-air heat pumps on a shared tempered loop; also verify the condenser plant is not `GroundSource` and that all source/terminal IDREFs resolve | The L200 schema cannot directly distinguish this topology from every other heat-pump arrangement | Manual topology review | Always required |
| `target_zone_names` | Terminal/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all terminal-served premises to exact zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Plant topology may be newly created rather than merged. Apply audited heat-pump COPs and plant properties with focused modifiers.
