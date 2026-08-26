# Create Four-Pipe Fan Coil HVAC

Adds a four-pipe fan-coil unit to each selected unserved zone and creates the required hot- and chilled-water infrastructure through openstudio-standards.

## Use this measure when

- BuildingSync identifies four-pipe fan-coil zone delivery with heating and cooling water.
- The baseline zones are unserved.

Do not use it to replace existing HVAC or merely change plant properties.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Comma-separated exact model thermal-zone names; blank selects all | Optional; blank |
| `standards_template` | Template used to create terminal and plant topology | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Measure selection | `PrincipalHVACSystemType`; fallback `DeliveryType/ZoneEquipment` fan-coil type plus linked heating and cooling plants | Require four-pipe or both hot-water and chilled-water coil evidence | Enum/relationship mapping | High for explicit type; medium for inferred plant links |
| `target_zone_names` | HVAC `LinkedPremises` thermal-zone, space, or section IDrefs | Resolve linked premises to exact model thermal-zone names | Join names with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow/baseline policy | None | Not an audit property |

## Usage

1. Resolve all served premises to zone names.
2. Confirm the zones have no existing HVAC.
3. Run this measure, then use plant/equipment modifiers for audited capacities and efficiencies.

## Limitations

The measure may create new hot-water and chilled-water loops even when compatible plants already exist. It does not infer or merge audit plant topology.
