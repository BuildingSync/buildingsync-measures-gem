# Create Chilled-Beam HVAC

Adds four-pipe chilled-beam terminals, a dedicated primary outdoor-air loop, and new supporting hot- and chilled-water plants to unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Supporting plant construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/Convection/ConvectionType = "Chilled beam"`; `Delivery/CoolingSourceID/@IDref` resolves to a source with `CoolingMedium = "Chilled water"`; `HeatingSourceID/@IDref` resolves to `HeatingMedium = "Hot water"`; primary ventilation is corroborated by `OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Dedicated outdoor air system"` | Require explicit chilled-beam terminals plus chilled-water, hot-water, and primary-air evidence for this measure's topology | Exact enums plus IDREF relationships | High for beam type; high for full topology only when all links resolve |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Chilled Beam"` | Use only if L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Cooling, heating, or DOAS evidence is missing; source IDs cannot be resolved; or ConvectionType is `Other`/`Unknown` | Confirm active four-pipe beam topology and primary ventilation manually | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | Chilled-beam delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve beam-served premises to exact model thermal zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

This measure creates four-pipe beams because that terminal type has explicit heating and cooling plant connections in OpenStudio 3.10. Supporting plants are first generated from standards fan-coil infrastructure; the temporary fan coils are removed. The primary-air loop contains outdoor-air intake and a fan but no audited conditioning coils, heat recovery, or humidity controls. Apply those details with focused modifiers or downstream workflow steps.
