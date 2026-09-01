# Replace HVAC with Low-Temperature Radiant

Replaces HVAC dedicated to selected zones with hydronic low-temperature radiant heating and cooling.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones to replace | Required; comma-separated |
| `standards_template` | Radiant system construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/Radiant/RadiantType = "Radiant floor or ceiling"`; `HeatingSourceID/@IDref` resolves to `HeatingMedium = "Hot water"`; `CoolingSourceID/@IDref` resolves to `CoolingMedium = "Chilled water"` | Require proposed floor/ceiling radiant delivery and both hydronic source relationships | Exact enum plus IDREF relationships | High when all components resolve |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Other"` | No radiant principal-system enum exists; `Other` is weak and never sufficient by itself | Exact enum, non-unique | Low |
| MANUAL CHECK | Always verify suitable modeled floor/ceiling surfaces and complete existing shared-system scope; review missing proposed status, heating, cooling, or IDREF evidence | RadiantType alone does not prove the measure's hydronic heating-and-cooling topology or model suitability | Manual topology/model review | Always required for surfaces; required for any unmapped component |
| `target_zone_names` | Proposed radiant delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete replacement scope to exact model thermal zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Partial shared-air-loop removal is rejected, and pre-existing plants are preserved. Zones must contain modeled surfaces. The standards implementation alters constructions and assigns radiant surfaces; BuildingSync surface mapping is frequently incomplete. Model edits are not transactional.
