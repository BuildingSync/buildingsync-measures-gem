# Replace HVAC with Packaged Rooftop AC

Replaces systems dedicated to selected zones with packaged single-zone rooftop air conditioners.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact zones whose HVAC is replaced | Required; comma-separated |
| `standards_template` | Replacement construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"` + `ZoningSystemType = "Single zone"` + `Deliveries/Delivery/DeliveryType/CentralAirDistribution/AirDeliveryType = "Central fan"`; heating resolves to `HeatingSourceType/Furnace/FurnaceType = "Warm air"`, not `HeatPump` | Require proposed packaged DX, single-zone central delivery, and non-heat-pump heating | Exact enums plus IDREF relationships | High when all records resolve |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop Air Conditioner"` | Use only if proposed L200 evidence is unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status, zoning, delivery, or heating evidence is missing/ambiguous, or heat-pump heating is present | Distinguish PSZ-AC from PSZ-HP and multizone PVAV; confirm full removal scope | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Proposed HVAC/source/delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete served scope and include all zones on affected shared loops | Join exact names | Partial shared-loop replacement is rejected |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

## Usage and limitations

Resolve complete serving scope, checkpoint the model, and run the measure. Existing plant loops are preserved. Apply audited controls and efficiencies with focused modifiers. OpenStudio edits are not transactional.
