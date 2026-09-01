# Replace HVAC with Chilled Beams

Replaces HVAC dedicated to selected zones with four-pipe chilled beams, a primary outdoor-air loop, and new supporting plants.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones to replace | Required; comma-separated |
| `standards_template` | Supporting plant construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/Convection/ConvectionType = "Chilled beam"`; `CoolingSourceID/@IDref` resolves to `CoolingMedium = "Chilled water"`; `HeatingSourceID/@IDref` resolves to `HeatingMedium = "Hot water"`; primary ventilation is corroborated by `OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Dedicated outdoor air system"` | Require proposed active beam, both hydronic circuits, and primary-air evidence | Exact enums plus IDREF relationships | High only when full topology resolves |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Chilled Beam"` | Use only if proposed L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status, cooling, heating, DOAS, or source IDREF evidence is missing/unknown | Confirm active four-pipe beam topology and complete existing air-loop scope | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | Proposed beam delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve the complete affected air-loop service scope | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Partial shared-air-loop removal is rejected. Existing plant loops are preserved rather than inferred as reusable; new beam plants are created. The primary-air loop has outdoor-air intake and a fan but no audited conditioning coils, heat recovery, or humidity controls. Model edits are not transactional.
