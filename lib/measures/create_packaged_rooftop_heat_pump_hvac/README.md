# Create Packaged Rooftop Heat Pump HVAC

Adds packaged single-zone rooftop heat pumps to selected unserved zones.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Exact model zone names; blank selects all | Optional; comma-separated |
| `standards_template` | openstudio-standards construction template | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; fallback packaged DX cooling and heat-pump heating plus single-zone delivery | Require explicit or combined packaged rooftop heat-pump evidence | Enum mapping | High for explicit L100; medium for L200 inference |
| `target_zone_names` | HVAC `LinkedPremises` thermal-zone, space, or section IDrefs | Resolve every linked premise to exact model zone names | Join with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow policy | None | Not audit data |

## Usage and limitations

Use only on unserved zones; use the paired replacement measure for retrofits. Apply audited cooling, heating, and supplemental-heating efficiencies afterward with the focused efficiency modifier.
