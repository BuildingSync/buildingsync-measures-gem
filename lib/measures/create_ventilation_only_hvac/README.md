# Create Ventilation-Only HVAC

Adds outdoor-air delivery without space heating or cooling to unserved zones. The air loop, outdoor-air system, and fan are constructed directly because openstudio-standards 0.8.2 does not recognize a `Ventilation Only` system key.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Supply only"` + `HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/NoHeating` present + `CoolingSources/CoolingSource/CoolingSourceType/NoCooling` present + `Deliveries/Delivery/DeliveryType/CentralAirDistribution` present | Require positive no-heating and no-cooling elements; missing source records do not prove their absence | Exact enum/element conjunction | High only when all facts are explicit |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Ventilation Only"` | Use only if L200 component records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Heating or cooling records are merely absent, ventilation type is not `Supply only`, or the central-air delivery cannot be joined to the ventilation system | Confirm the measure will not omit intended thermal conditioning | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Mechanical-ventilation, delivery, or HVAC-system `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete served scope to exact model names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. This measure does not provide zone heating or cooling; separate systems may be needed by the workflow.
