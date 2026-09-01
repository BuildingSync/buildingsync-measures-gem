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
| Measure selection — L200 (preferred) | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/ZoneEquipment/FanBased/FanBasedDistributionType/FanCoil/FanCoilType = "Fan coil 4 pipe"` and `HVACPipeConfiguration = "4 pipe"`; `Delivery/HeatingSourceID/@IDref` joins a source with `HeatingMedium = "Hot water"`; `Delivery/CoolingSourceID/@IDref` joins a source with `CoolingMedium = "Chilled water"` | Require the explicit fan-coil enum and both hydronic circuits | Exact enums plus IDREF relationships | High when all components are present |
| Measure selection — L100/L000 fallback only | `HVACSystem/PrincipalHVACSystemType = "Four Pipe Fan Coil Unit"` | Use only if the L200 delivery and source records are unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Fan-coil type or pipe configuration is `Other`/`Unknown`, either heating or cooling source link is missing, or linked plants cannot be resolved | Confirm two independent water coils and four-pipe operation | Manual topology review | Required if any component cannot be mapped directly |
| `target_zone_names` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; alternatives: `LinkedPremises/Space/LinkedSpaceID/@IDref` and `LinkedPremises/Section/LinkedSectionID/@IDref` | Resolve linked premises to exact model thermal-zone names | Join names with commas | Consumer owns ID resolution |
| `standards_template` | No direct field | Workflow/baseline policy | None | Not an audit property |

## Usage

1. Resolve all served premises to zone names.
2. Confirm the zones have no existing HVAC.
3. Run this measure, then use plant/equipment modifiers for audited capacities and efficiencies.

## Limitations

The measure may create new hot-water and chilled-water loops even when compatible plants already exist. It does not infer or merge audit plant topology.
