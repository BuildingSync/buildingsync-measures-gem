# Replace HVAC with Warm-Air Furnace

Removes HVAC dedicated to explicitly selected zones and installs the `Forced Air Furnace` topology.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones to replace | Required; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/Furnace/FurnaceType = "Warm air"` + `HeatingSource/HeatingMedium = "Air"` + associated `Deliveries/Delivery/DeliveryType/CentralAirDistribution`; `Delivery/HeatingSourceID/@IDref` joins the records | Require proposed warm-air furnace and central-air delivery evidence | Exact enums plus IDREF relationship | High when all records resolve |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Warm Air Furnace"` | Use only if proposed L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status, HeatingMedium, central delivery, or source-to-delivery relationship is missing/unknown, or FurnaceType is not `Warm air` | Confirm forced-air topology, cooling intent, and complete existing shared-loop scope | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Proposed heating-source/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete replacement scope to exact model thermal-zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Partial removal of shared air loops is rejected; expand the target scope to every served zone. Existing plant loops are preserved. Model edits are not transactional, so retain an input-model copy before replacement.
