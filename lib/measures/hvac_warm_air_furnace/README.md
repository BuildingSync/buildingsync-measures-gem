# Warm-Air Furnace HVAC

Creates warm-air furnace systems in unserved zones or replaces HVAC dedicated to selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/Furnace/FurnaceType = "Warm air"`; `HeatingMedium = "Air"`; associated `Deliveries/Delivery/DeliveryType/CentralAirDistribution`; `Delivery/HeatingSourceID/@IDref` joins the records | Active/baseline facts select `create`; same proposed facts with `@Status = "Proposed"` select `replace` | High when source, medium, delivery, and IDREF agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Warm Air Furnace"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status or heating medium/central delivery/source-to-delivery evidence is missing or unknown, `FurnaceType` is not `Warm air`, or delivery is zone-local | Confirm intended furnace topology and complete replacement scope | Required if any condition applies |
| `target_zone_names` | Heating-source/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve exact served zones and complete shared-loop scope for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Depending on standards behavior, synthesis may create air loops or zone unit heaters. Replacement preserves plants.