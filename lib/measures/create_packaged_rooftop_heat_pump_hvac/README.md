# Create Packaged Rooftop Heat Pump HVAC

Adds packaged single-zone rooftop heat pumps to selected unserved zones.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zone names; blank selects all | Optional; comma-separated |
| `standards_template` | openstudio-standards construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary heat pump"` + `HeatingSources/HeatingSource/HeatingSourceType/HeatPump/HeatPumpType = "Packaged Unitary"` + `HeatingAndCoolingSystems/ZoningSystemType = "Single zone"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/AirDeliveryType = "Central fan"` | Require all four facts for the same linked system | Exact enums plus IDREF relationships | High when cooling, heating, and delivery records are joined |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop Heat Pump"` | Use only if L200 component evidence is unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | The packaged-unitary cooling and heating records are not linked, zoning/delivery evidence is missing, or furnace heating is also indicated | Distinguish PSZ-HP from PTHP, split heat pump, and multizone equipment | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | `HVACSystem/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref` or associated source/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve every linked premise to exact model zones | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

## Usage and limitations

Use only on unserved zones; use the paired replacement measure for retrofits. Apply audited cooling, heating, and supplemental-heating efficiencies afterward with the focused efficiency modifier.
