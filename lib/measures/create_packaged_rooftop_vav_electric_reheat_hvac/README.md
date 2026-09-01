# Create Packaged Rooftop VAV with Electric Reheat

Adds packaged multizone VAV with parallel fan-powered electric-reheat terminals to selected unserved zones.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"` + `CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box fan powered with reheat"` + `ReheatSource = "Local electric resistance"` | Require packaged DX, multizone fan-powered VAV, and electric terminal reheat evidence | Exact enum conjunction | High when all fields apply to the same delivery/source relationship |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop VAV with Electric Reheat"` | Use only if L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Packaged DX, fan-powered terminal, or electric reheat evidence is absent/unknown, or the delivery/source relationship is unresolved | Distinguish this system from built-up VAV and non-fan-powered reheat | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete served scope to exact model names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Use only on unserved zones. This topology does not request a hydronic reheat plant. Apply audited controls and efficiencies with focused modifiers.
