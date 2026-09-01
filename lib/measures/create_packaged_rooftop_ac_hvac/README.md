# Create Packaged Rooftop AC HVAC

Adds packaged single-zone rooftop air conditioners to selected unserved zones.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zone names; blank selects all | Optional; comma-separated |
| `standards_template` | openstudio-standards construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"` + `HeatingAndCoolingSystems/ZoningSystemType = "Single zone"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/AirDeliveryType = "Central fan"`; heating should resolve to `HeatingSourceType/Furnace/FurnaceType = "Warm air"`, not `HeatPump` | Require packaged DX cooling, single-zone central delivery, and non-heat-pump heating evidence | Exact enums plus IDREF relationships | High when source and delivery IDs resolve consistently |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop Air Conditioner"` | Use only if L200 evidence is unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Zoning or central-air delivery is missing, the heating source is absent/ambiguous, or heat-pump heating is present | Distinguish PSZ-AC from PSZ-HP, multizone PVAV, and cooling-only equipment | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | `HVACSystem/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref` or associated `Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve every linked premise to exact model zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

## Usage and limitations

Use only on unserved zones; use `replace_with_packaged_rooftop_ac_hvac` for retrofit replacement. The measure creates topology and default performance. Apply audited SAT, economizer, and equipment efficiencies afterward with focused modifiers.
