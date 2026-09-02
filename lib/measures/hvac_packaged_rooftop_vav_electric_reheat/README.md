# Packaged Rooftop VAV with Electric Reheat HVAC

Creates packaged multizone VAV with fan-powered electric-reheat terminals or replaces dedicated HVAC for selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/ZoningSystemType = "Multi zone"`; `CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged/unitary direct expansion/RTU"`; `Deliveries/Delivery/DeliveryType/CentralAirDistribution/TerminalUnit = "VAV terminal box fan powered with reheat"`; `ReheatSource = "Local electric resistance"` | Active/baseline facts select `create`; matching proposed facts with `@Status = "Proposed"` select `replace` | High when all exact enums and relationships agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Rooftop VAV with Electric Reheat"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status, packaged DX, fan-powered terminal, or electric reheat is absent/unknown, or delivery/source relationships are unresolved | Confirm packaged topology and complete replacement scope | Required if any condition applies |
| `target_zone_names` | `Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve complete multizone scope; include every zone on affected loops for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Creation requires unserved zones. Replacement rejects partial shared-loop removal and preserves plants.