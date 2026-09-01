# Create Warm-Air Furnace HVAC

Adds warm-air furnace heating to selected unserved zones using the `Forced Air Furnace` topology.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/Furnace/FurnaceType = "Warm air"` + `HeatingSource/HeatingMedium = "Air"` + associated `Deliveries/Delivery/DeliveryType/CentralAirDistribution`; `Delivery/HeatingSourceID/@IDref` joins the records | Require explicit warm-air furnace and central-air delivery evidence | Exact enums plus IDREF relationship | High when all records resolve |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Warm Air Furnace"` | Use only if L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | FurnaceType is not `Warm air`, HeatingMedium is absent/unknown, delivery is zone-local, or source-to-delivery IDREF is unresolved | Confirm forced-air furnace topology and whether cooling is also intended | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Heating-source/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all furnace-served premises to exact model thermal-zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

The standards topology may use air loops, zone unit heaters, or both depending on template and model context. Apply audited furnace efficiency and air-loop controls with the focused modifier measures.
