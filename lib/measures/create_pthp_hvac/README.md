# Create PTHP HVAC

Adds one packaged terminal heat pump to each selected, currently unserved thermal zone.

## Use this measure when

- BuildingSync identifies a Packaged Terminal Heat Pump.
- The baseline zones do not already have HVAC.

Do not use it for replacement or efficiency-only changes.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Comma-separated exact model thermal-zone names; blank selects all zones | Optional; blank |
| `standards_template` | Template used by openstudio-standards | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged terminal heat pump (PTHP)"` + `HeatingSources/HeatingSource/HeatingSourceType/HeatPump/HeatPumpType = "Packaged Terminal"` + associated `Delivery/DeliveryType/ZoneEquipment`; use `HeatPump/CoolingSourceID/@IDref`, `Delivery/HeatingSourceID/@IDref`, and `Delivery/CoolingSourceID/@IDref` to verify one system | Require matching terminal heat-pump cooling, heating, and zone-delivery records | Exact enums plus IDREF relationships | High when records are linked |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Terminal Heat Pump"` | Use only if L200 component evidence is unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Either exact enum is absent, cooling/heating/delivery records cannot be joined, or a central-air delivery is indicated | Confirm PTHP topology and served-zone scope manually | Manual classification | Required if any listed condition applies |
| `target_zone_names` | `HVACSystem/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; component-level `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives: `LinkedPremises/Space/LinkedSpaceID/@IDref` and `LinkedPremises/Section/LinkedSectionID/@IDref` | Resolve every IDREF to exact model thermal-zone names | Join names with commas | Consumer owns ID resolution |
| `standards_template` | No direct BuildingSync field | Workflow/baseline policy | None | Not an audit property |

## Usage

1. Resolve linked premises to model zone names.
2. Confirm the zones are unserved.
3. Run this measure, then apply audited COP values with the focused efficiency modifier.

## Limitations

Topology and default performance are supplied by openstudio-standards. Audit-specific heating, cooling, and supplemental-heating efficiencies are intentionally separate.
