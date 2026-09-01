# Create PTAC HVAC

Adds one packaged terminal air conditioner to each selected, currently unserved thermal zone.

## Use this measure when

- BuildingSync identifies a Packaged Terminal Air Conditioner.
- The baseline zones do not already have HVAC.

Do not use it to replace existing HVAC; use `replace_with_ptac_hvac` instead. Apply efficiency changes afterward with the focused existing-equipment modifier.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Comma-separated exact OpenStudio thermal-zone names; blank selects all zones | Optional; blank |
| `standards_template` | Template used by openstudio-standards | `90.1-2013`, `90.1-2016`, or `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged terminal air conditioner (PTAC)"`; associated `Delivery/DeliveryType/ZoneEquipment`; `CoolingSourceID/@IDref` joins the delivery to the cooling source | Require the PTAC enum and a zone-equipment delivery serving the same premises | Exact enum plus IDREF relationship | High when all three records agree |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Packaged Terminal Air Conditioner"` | Use only when the L200 source/delivery records are unavailable; do not override contradictory L200 data | Exact enum | Medium |
| MANUAL CHECK | PTAC enum is missing, source-to-delivery IDREF is unresolved, delivery is central rather than zone equipment, or heating configuration matters to the intended model | Confirm the equipment is a PTAC rather than a generic packaged DX unit or PTHP | Manual classification | Required if any listed condition applies |
| `target_zone_names` | `HVACSystem/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; component-level `HeatingSource`, `CoolingSource`, or `Delivery` `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives: `LinkedPremises/Space/LinkedSpaceID/@IDref` and `LinkedPremises/Section/LinkedSectionID/@IDref` | Resolve every IDREF to exact OpenStudio thermal-zone names | Join resolved names with commas | Consumer owns BuildingSync-ID-to-model-name resolution |
| `standards_template` | No direct BuildingSync field | Workflow/baseline policy | None | Not an audit property |

## Usage

1. Resolve linked premises to model zone names.
2. Confirm those zones are unserved.
3. Run the measure, then optionally run an existing-equipment efficiency modifier on the created coils.

## Limitations

The openstudio-standards PTAC fuel configuration is currently fixed to the established gem policy. This measure creates topology only; it does not apply audit COP or heating-efficiency values.
