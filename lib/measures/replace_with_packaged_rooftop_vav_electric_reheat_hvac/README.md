# Replace HVAC with Packaged Rooftop VAV and Electric Reheat

Replaces complete zone-serving HVAC with packaged multizone VAV and parallel fan-powered electric-reheat terminals.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"` + `CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box fan powered with reheat"` + `ReheatSource = "Local electric resistance"` | Require the complete proposed packaged, fan-powered VAV, electric-reheat topology | Exact enum conjunction | High when all records apply to the same relationship |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop VAV with Electric Reheat"` | Use only if proposed L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status, packaged DX, fan-powered terminal, or electric reheat evidence is missing/unknown | Distinguish from built-up VAV and confirm complete existing shared-loop scope | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | Proposed delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Include every zone on affected shared loops | Join exact model names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved; no hydronic reheat plant is requested. Checkpoint before replacement and apply audited controls and efficiencies afterward.
