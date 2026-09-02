# PTAC HVAC

Creates packaged terminal air conditioners in unserved zones or replaces HVAC dedicated to explicitly selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` adds topology; `replace` removes dedicated existing HVAC before adding topology | `create` |
| `target_zone_names` | Comma-separated exact OpenStudio thermal-zone names; blank selects all zones only for `create` | Blank |
| `standards_template` | openstudio-standards construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged terminal air conditioner (PTAC)"`; associated `Deliveries/Delivery/DeliveryType/ZoneEquipment`; `Delivery/CoolingSourceID/@IDref` joins the records | For `create`, use matching active/baseline facts. For `replace`, require the same facts on the proposed `HVACSystem` with `@Status = "Proposed"` | High when the exact enum, zone delivery, and IDREF agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Terminal Air Conditioner"` | Use only when L200 records are unavailable and not contradictory; for `replace`, require a proposed HVAC system | Medium |
| MANUAL CHECK | PTAC enum or proposed status is missing; the source-to-delivery IDREF is unresolved; delivery is central; or heating configuration affects the intended model | Confirm PTAC rather than generic packaged DX or PTHP, and confirm complete replacement scope | Required if any listed condition applies |
| `target_zone_names` | HVAC/component `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedPremises/Space/LinkedSpaceID/@IDref` and `LinkedPremises/Section/LinkedSectionID/@IDref` | Resolve every IDREF to exact model-zone names; `replace` must include every zone on affected shared loops | Consumer owns BuildingSync-ID-to-model-name resolution |
| `standards_template` | No direct BuildingSync field | Workflow/baseline policy | Not audit data |

Replacement preserves plant loops and rejects partial shared-air-loop removal before mutation. Creation requires unserved zones. Efficiency values belong in focused modifiers.