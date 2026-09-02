# Dedicated Outdoor Air System HVAC

Creates a dedicated outdoor-air system or replaces HVAC dedicated to selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Workflow template recorded for consistency | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Dedicated outdoor air system"`; corroborate `HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution` and matching `LinkedPremises` | Active/baseline records select `create`; same facts on `HVACSystem[@Status = "Proposed"]` select `replace` | High when dedicated ventilation and delivery premises agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Dedicated Outdoor Air System"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status is unclear; `VentilationType` is `Supply only`, `Heat recovery ventilator`, `Energy recovery ventilator`, `Other`, or `Unknown`; or a dedicated outdoor-air loop is not established | Confirm DOAS topology and replacement scope | Required if any condition applies |
| `target_zone_names` | `OtherHVACSystem/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref` and associated delivery/HVAC-system `LinkedPremises`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all served premises; include complete shared-loop scope for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Direct construction does not query standards data |

This topology supplies ventilation air only. Apply terminal heating/cooling with a separate topology when required.