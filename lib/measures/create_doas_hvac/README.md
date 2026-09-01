# Create Dedicated Outdoor Air System

Adds a DOAS air loop to selected unserved zones. The loop, outdoor-air system, and fan are constructed directly because the pinned standards API did not create a DOAS loop in minimal models. No outdoor-air heating/cooling coils or separate zone sensible-conditioning system are added.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Dedicated outdoor air system"`; corroborate with `HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution` and matching `LinkedPremises` | Require the exact mechanical-ventilation enum and a dedicated served scope | Exact enum plus premise/delivery relationships | High for the ventilation type; medium for reconstructing air-loop relationships |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Dedicated Outdoor Air System"` | Use only if the L200 mechanical-ventilation record is unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | `VentilationType` is `Supply only`, `Heat recovery ventilator`, `Energy recovery ventilator`, `Other`, or `Unknown`; or the record does not establish that ventilation is delivered by a dedicated outdoor-air air loop | Confirm DOAS topology, conditioning, heat recovery, and served zones manually | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | `OtherHVACSystem/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`, associated `Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`, or HVAC-system equivalent; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete served scope to exact model names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. Configure SAT, economizer, and heat recovery afterward with focused modifiers. Zone sensible loads may require separate terminals.
