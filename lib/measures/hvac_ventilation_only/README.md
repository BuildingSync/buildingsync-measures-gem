# Ventilation-Only HVAC

Creates central supply-only ventilation without heating or cooling, or replaces dedicated HVAC for selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Workflow template recorded for consistency | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Supply only"`; `HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/NoHeating`; `CoolingSources/CoolingSource/CoolingSourceType/NoCooling`; `Deliveries/Delivery/DeliveryType/CentralAirDistribution` | Active/baseline records select `create`; require the same records on `HVACSystem[@Status = "Proposed"]` for `replace` | High only when explicit no-heating/no-cooling and central supply delivery agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Ventilation Only"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status is unclear, heating/cooling are merely absent rather than explicit, ventilation type is not `Supply only`, or central delivery cannot be joined | Confirm ventilation-only topology and complete replacement scope | Required if any condition applies |
| `target_zone_names` | Ventilation/delivery/HVAC `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all premises; include every shared-loop zone for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Direct construction does not query standards data |

This measure constructs topology directly. Replacement preserves plant loops and rejects partial shared-loop removal.