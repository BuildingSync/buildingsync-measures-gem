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
| Measure selection | `HVACSystem/PrincipalHVACSystemType`; fallback `CoolingSourceType/DX/DXSystemType` | Select when L100 is `Packaged Terminal Air Conditioner`; otherwise require PTAC DX evidence plus zone fan delivery | Enum mapping only | High for L100; medium for L200 inference |
| `target_zone_names` | `HVACSystem/LinkedPremises/.../ThermalZone/@IDref`; fallback Space or Section IDrefs | Consumer resolves premise references to exact model thermal-zone names | Join resolved names with commas | Mapping from BuildingSync IDs to model names is consumer policy |
| `standards_template` | No direct BuildingSync field | Workflow/baseline policy | None | Not an audit property |

## Usage

1. Resolve linked premises to model zone names.
2. Confirm those zones are unserved.
3. Run the measure, then optionally run an existing-equipment efficiency modifier on the created coils.

## Limitations

The openstudio-standards PTAC fuel configuration is currently fixed to the established gem policy. This measure creates topology only; it does not apply audit COP or heating-efficiency values.
