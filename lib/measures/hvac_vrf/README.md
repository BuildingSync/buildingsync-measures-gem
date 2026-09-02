# VRF HVAC

Creates variable-refrigerant-flow outdoor units and terminals or replaces HVAC dedicated to selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Variable refrigerant flow"`; `Deliveries/Delivery/DeliveryType/ZoneEquipment/FanBased/FanBasedDistributionType/FanCoil/FanCoilType = "VRF terminal units"`; join `Delivery/CoolingSourceID/@IDref` and, when present, `Delivery/HeatingSourceID/@IDref` | Active/baseline facts select `create`; equivalent proposed facts with `@Status = "Proposed"` select `replace` | High when exact source/terminal enums and one VRF group are established |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "VRF Terminal Unit"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status is unclear, evidence is only a generic heat pump, `FanCoilType` is absent/unknown, or IDREFs cannot establish one complete VRF group | Confirm full outdoor-unit group and replacement scope | Required if any condition applies |
| `target_zone_names` | VRF delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve every terminal zone; replacement must include all zones on each affected outdoor unit and air loop | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Replacement preflight rejects partial shared outdoor-unit removal as well as partial shared-air-loop removal.