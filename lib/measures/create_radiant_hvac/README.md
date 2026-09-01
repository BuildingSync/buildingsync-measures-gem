# Create Low-Temperature Radiant HVAC

Adds hydronic low-temperature radiant heating and cooling plus supporting plants to unserved zones with modeled surfaces.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Radiant system construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/Radiant/RadiantType = "Radiant floor or ceiling"`; `Delivery/HeatingSourceID/@IDref` resolves to a source with `HeatingMedium = "Hot water"`; `Delivery/CoolingSourceID/@IDref` resolves to a source with `CoolingMedium = "Chilled water"` | Require explicit floor/ceiling radiant delivery and both hydronic source relationships for this heating-and-cooling measure | Exact enum plus IDREF relationships | High when all components resolve |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Other"` | The XSD has no radiant principal-system enum; `Other` is only a weak fallback and never sufficient by itself | Exact enum, non-unique | Low |
| MANUAL CHECK | Always verify suitable modeled floor/ceiling surfaces; also review any missing heating source, cooling source, or IDREF relationship | This measure requires hydronic heating and cooling plus assignable surfaces, which `RadiantType` alone does not prove | Manual topology/model review | Always required for surface suitability; required for any unmapped component |
| `target_zone_names` | Radiant delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve radiant-served premises to exact model thermal zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Zones must contain modeled surfaces. The standards implementation modifies constructions to support internal-source radiant surfaces and selects the actual surfaces. BuildingSync often does not identify surface assignments, so geometry-specific mapping remains uncertain. Plant temperatures and efficiencies remain separate focused modifications.
