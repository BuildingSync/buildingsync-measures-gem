# Replace HVAC with Packaged Rooftop Heat Pump

Replaces systems dedicated to selected zones with packaged single-zone rooftop heat pumps.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary heat pump"` + `HeatingSources/HeatingSource/HeatingSourceType/HeatPump/HeatPumpType = "Packaged Unitary"` + `ZoningSystemType = "Single zone"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/AirDeliveryType = "Central fan"` | Require all four facts for the same proposed linked system | Exact enums plus IDREF relationships | High when records are joined |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop Heat Pump"` | Use only if proposed L200 evidence is unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status is unclear, packaged-unitary heating/cooling records are not linked, zoning/delivery is missing, or furnace heating is also indicated | Distinguish PSZ-HP from PTHP, split heat pumps, and multizone systems | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Proposed HVAC/source/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete served scope and include all zones on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

## Usage and limitations

Resolve complete scope, checkpoint the model, and run the measure. Existing plant loops are preserved. Apply audited controls and COPs afterward. OpenStudio edits are not transactional.
