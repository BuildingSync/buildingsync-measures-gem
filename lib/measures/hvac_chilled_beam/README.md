# Chilled-Beam HVAC

Creates four-pipe chilled beams, supporting plants, and a primary-air loop, or replaces dedicated HVAC for selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Template used to create supporting plants | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/Convection/ConvectionType = "Chilled beam"`; `Delivery/CoolingSourceID/@IDref` resolves to `CoolingMedium = "Chilled water"`; `Delivery/HeatingSourceID/@IDref` resolves to `HeatingMedium = "Hot water"`; corroborate `OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Dedicated outdoor air system"` | Active/baseline facts select `create`; matching proposed facts with `@Status = "Proposed"` select `replace` | High when beam, both hydronic sources, and DOAS evidence agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Chilled Beam"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status, cooling, heating, DOAS, or source IDREF evidence is missing/unknown, or `ConvectionType` is `Other`/`Unknown` | Confirm complete four-pipe-beam and primary-air topology | Required if any condition applies |
| `target_zone_names` | Delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all beam zones; include complete shared-loop scope for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Supporting plants are synthesized through temporary fan coils. Replacement preserves pre-existing plants and creates new beam plants.