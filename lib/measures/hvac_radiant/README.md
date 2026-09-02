# Low-Temperature Radiant HVAC

Creates hydronic low-temperature radiant heating and cooling or replaces dedicated HVAC for selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Radiant Slab construction template | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/Radiant/RadiantType = "Radiant floor or ceiling"`; `HeatingSourceID/@IDref` resolves to `HeatingMedium = "Hot water"`; `CoolingSourceID/@IDref` resolves to `CoolingMedium = "Chilled water"` | Active/baseline facts select `create`; same facts on `HVACSystem[@Status = "Proposed"]` select `replace` | High when radiant delivery and both source joins agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Other"` | Weak fallback only; never override contradictory L200 data | Low |
| MANUAL CHECK | Always verify suitable modeled floor/ceiling surfaces. Also review missing proposed status, heating/cooling source or IDREF evidence, and complete existing shared-system scope for `replace` | Manual geometry and topology review | Always required for surfaces; additionally required for any missing evidence |
| `target_zone_names` | Radiant delivery `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve exact zones and complete shared scope for replacement | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Not audit data |

Both operations fail before mutation when a selected zone has no modeled surfaces. Replacement preserves existing plants.