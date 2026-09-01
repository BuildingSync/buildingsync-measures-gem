# Create VRF HVAC

Adds variable-refrigerant-flow outdoor equipment and one terminal per selected unserved zone.

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zones; blank selects all | Optional; comma-separated |
| `standards_template` | Construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Variable refrigerant flow"` + `Deliveries/Delivery/DeliveryType/ZoneEquipment/FanBased/FanBasedDistributionType/FanCoil/FanCoilType = "VRF terminal units"`; join terminals with `Delivery/CoolingSourceID/@IDref` and, when present, `Delivery/HeatingSourceID/@IDref` | Require both explicit VRF source and terminal enums | Exact enums plus IDREF relationships | High when outdoor-unit and terminal records are linked |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "VRF Terminal Unit"` | Use only if L200 source/terminal records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Only a generic heat-pump source is present, `FanCoilType` is absent/unknown, or source/terminal IDREFs cannot establish one VRF service group | Confirm the outdoor-unit/terminal topology and complete served scope | Manual topology review | Required if any listed condition applies |
| `target_zone_names` | VRF delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all terminal-served premises to exact model thermal-zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

The standards template determines heat-recovery configuration, capacities, curves, and supplemental heat. Apply audited VRF COPs with the focused efficiency modifier.
