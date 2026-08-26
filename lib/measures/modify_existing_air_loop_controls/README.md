# Modify Existing Air Loop Controls

Changes supply-air design temperatures and/or economizer controls on exact, named existing air loops. It never adds, removes, or classifies HVAC.

## Arguments and BuildingSync mapping

| Argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `target_air_loop_names` | `HVACSystem/@ID`, delivery/equipment identifiers, linked-premise associations | Consumer maps BuildingSync records to exact OpenStudio loop names | Comma-separated names | No direct standard ID-to-model-name mapping |
| `cooling_supply_air_temperature_c` | `DeliveryType/CentralAirDistribution/FanBased/CoolingSupplyAirTemperature` | Use the value for the matched central-air delivery | °C = (°F − 32) × 5/9 | High when delivery is explicitly linked |
| `heating_supply_air_temperature_c` | `.../FanBased/HeatingSupplyAirTemperature` | Same delivery-selection rule | °C = (°F − 32) × 5/9 | High when present |
| `economizer_control_type` | `.../FanBased/AirSideEconomizer/AirSideEconomizerType` | Map Dry bulb, Enthalpy, or None; other values require workflow policy | Enum mapping | Medium; integrated/nonintegrated semantics are not represented |
| `economizer_high_limit_dry_bulb_temperature_c` | `.../EconomizerDryBulbControlPoint` | Use only with a dry-bulb strategy | °F to °C | High |
| `economizer_high_limit_enthalpy_j_kg` | `.../EconomizerEnthalpyControlPoint` | Use only with an enthalpy strategy | Btu/lb × 2326 | High |

## Usage

1. Resolve the audit system to exact loop names.
2. Enable only the property groups to change.
3. Run once for loops sharing the same values.

Unmatched names are errors; loops without outdoor-air systems receive an economizer warning.
