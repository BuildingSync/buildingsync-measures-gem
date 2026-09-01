# Modify Existing Air Loop Controls

Changes supply-air design temperatures and/or economizer controls on exact, named existing air loops. It never adds, removes, or classifies HVAC.

## Arguments and BuildingSync mapping

| Argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `target_air_loop_names` | `HVACSystem/@ID`; `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/@ID`; `Delivery/EquipmentID`; `Delivery/LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref` | Resolve the selected HVAC/delivery record to exact OpenStudio air-loop names | Comma-separated names | **MANUAL CHECK:** BuildingSync IDs and `EquipmentID` are not OpenStudio names; an external ID-to-model-object crosswalk is required |
| `cooling_supply_air_temperature_c` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution/FanBased/CoolingSupplyAirTemperature` | Use only from the matched central-air delivery | °C = (°F − 32) × 5/9 | **MANUAL CHECK:** this audit value is an operating temperature setting, while the measure changes the OpenStudio sizing design temperature |
| `heating_supply_air_temperature_c` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution/FanBased/HeatingSupplyAirTemperature` | Use only from the matched central-air delivery | °C = (°F − 32) × 5/9 | **MANUAL CHECK:** operating setpoint and sizing design temperature are not necessarily equivalent |
| `economizer_control_type` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution/FanBased/AirSideEconomizer/AirSideEconomizerType` + sibling `EconomizerControl` | Map `None` → `NoEconomizer`; `Dry bulb temperature` + `Fixed`/`Differential` → `FixedDryBulb`/`DifferentialDryBulb`; `Enthalpy` + `Fixed`/`Differential` → `FixedEnthalpy`/`DifferentialEnthalpy` | Enum-pair mapping | **MANUAL CHECK:** `Nonintegrated`, `Demand controlled ventilation`, `Other`, and `Unknown` do not map directly; `ElectronicEnthalpy` also has no direct XSD enum |
| `economizer_high_limit_dry_bulb_temperature_c` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution/FanBased/AirSideEconomizer/EconomizerDryBulbControlPoint` | Use only with verified dry-bulb economizer evidence | °C = (°F − 32) × 5/9 | Direct value conversion after delivery resolution |
| `economizer_high_limit_enthalpy_j_kg` | `HVACSystem/HeatingAndCoolingSystems/Deliveries/Delivery/DeliveryType/CentralAirDistribution/FanBased/AirSideEconomizer/EconomizerEnthalpyControlPoint` | Use only with verified enthalpy economizer evidence | J/kg = Btu/lb × 2326 | Direct value conversion after delivery resolution |

## Usage

1. Resolve the audit system to exact loop names.
2. Enable only the property groups to change.
3. Run once for loops sharing the same values.

Unmatched names are errors; loops without outdoor-air systems receive an economizer warning.
