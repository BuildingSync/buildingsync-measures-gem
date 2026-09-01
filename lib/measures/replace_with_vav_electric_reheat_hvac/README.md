# Replace HVAC with VAV and Electric Reheat

Replaces complete serving systems with built-up VAV and parallel fan-powered electric-reheat terminals.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"` + `CoolingSources/CoolingSource/CoolingSourceType/CoolingPlantID/@IDref` resolving to `Plants/CoolingPlants/CoolingPlant/Chiller` + `CoolingSource/CoolingMedium = "Chilled water"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box fan powered with reheat"` + `ReheatSource = "Local electric resistance"` | Require proposed built-up VAV, central chiller, and fan-powered electric reheat | Exact enums/elements plus IDREF relationships | High when all records resolve |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "VAV with Electric Reheat"` | Use only if proposed L200 records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status, CoolingPlantID, fan-powered terminal, electric reheat, or packaged-versus-built-up distinction is unresolved | Confirm exact proposed topology and complete existing shared-loop scope | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | Proposed delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Include every zone on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Existing plants are preserved. Checkpoint before replacement and apply audit values afterward.
