# Dedicated Outdoor Air System HVAC

Creates a dedicated outdoor-air system or replaces HVAC dedicated to selected zones.

## Arguments

| Argument | Meaning | Default |
|---|---|---|
| `operation` | `create` or `replace` | `create` |
| `target_zone_names` | Exact comma-separated model zones; blank selects all only for `create` | Blank |
| `standards_template` | Workflow template recorded for consistency | `90.1-2019` |

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| `operation` and L200 selection (preferred) | `HVACSystem/OtherHVACSystems/OtherHVACSystem/OtherHVACType/MechanicalVentilation/VentilationType = "Dedicated outdoor air system"`; corroborate `HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution` and matching `LinkedPremises` | Active/baseline records select `create`; same facts on `HVACSystem[@Status = "Proposed"]` select `replace` | High when dedicated ventilation and delivery premises agree |
| L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Dedicated Outdoor Air System"` | Use only if L200 is unavailable and noncontradictory | Medium |
| MANUAL CHECK | Proposed status is unclear; `VentilationType` is `Supply only`, `Heat recovery ventilator`, `Energy recovery ventilator`, `Other`, or `Unknown`; or a dedicated outdoor-air loop is not established | Confirm DOAS topology and replacement scope | Required if any condition applies |
| `target_zone_names` | `OtherHVACSystem/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref` and associated delivery/HVAC-system `LinkedPremises`; alternatives `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve all served premises; include complete shared-loop scope for `replace` | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | Direct construction does not query standards data |

This topology supplies ventilation air only. It can be combined with a zone-equipment topology (PTAC, PTHP, fan coil, WLHP, GSHP, radiant, VRF). Run this measure after all other HVAC upgrades. Existing zone equipment is kept during both create and replace. The DOAS supplies outdoor air directly to each zone, and zone-unit outdoor air is set to 0 so the DOAS is the only ventilation source. See [DOAS layering](../../../docs/HVAC_MIGRATION.md#doas-layering-direct-to-zone).