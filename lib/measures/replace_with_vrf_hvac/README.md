# Replace HVAC with VRF

Removes HVAC dedicated to explicitly selected zones and installs variable-refrigerant-flow outdoor equipment and terminals.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones to replace | Required; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Variable refrigerant flow"` + `Deliveries/Delivery/DeliveryType/ZoneEquipment/FanBased/FanBasedDistributionType/FanCoil/FanCoilType = "VRF terminal units"`; use delivery/source IDREFs to identify one service group | Require explicit proposed VRF source and terminal enums | Exact enums plus IDREF relationships | High when outdoor-unit and terminal records are linked |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "VRF Terminal Unit"` | Use only if proposed L200 source/terminal records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status is unclear, only generic heat-pump evidence exists, FanCoilType is absent/unknown, or IDREFs do not establish the complete VRF group | Confirm proposed outdoor-unit topology and include every zone on affected existing VRF/air-loop groups | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | Proposed VRF delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve the complete outdoor-unit service scope to exact model thermal-zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

Partial removal of shared air loops or shared VRF outdoor units is rejected; include every zone served by each affected system. Existing plant loops are preserved. Model edits are not transactional, so retain an input-model copy.
