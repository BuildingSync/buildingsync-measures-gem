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
| Measure selection | `HVACSystem/PrincipalHVACSystemType`; fallback heat-pump `CoolingSourceType/DX/DXSystemType` and heating-source evidence | Select when L100 is `Packaged Terminal Heat Pump`; otherwise require terminal heat-pump evidence | Enum mapping only | High for L100; medium for inferred L200 evidence |
| `target_zone_names` | `HVACSystem/LinkedPremises/.../ThermalZone/@IDref`; fallback Space or Section IDrefs | Consumer resolves all linked premises to exact model zone names | Join names with commas | ID-to-model-name mapping is consumer policy |
| `standards_template` | No direct BuildingSync field | Workflow/baseline policy | None | Not an audit property |

## Usage

1. Resolve linked premises to model zone names.
2. Confirm the zones are unserved.
3. Run this measure, then apply audited COP values with the focused efficiency modifier.

## Limitations

Topology and default performance are supplied by openstudio-standards. Audit-specific heating, cooling, and supplemental-heating efficiencies are intentionally separate.
