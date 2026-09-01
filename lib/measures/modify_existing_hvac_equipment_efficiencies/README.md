# Modify Existing HVAC Equipment Efficiencies

Sets one efficiency metric on explicitly named existing coils or VRF outdoor units. Run it once per metric/value group.

## BuildingSync mapping

| Metric | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `dx_cooling_cop` | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/AnnualCoolingEfficiencyValue` + `AnnualCoolingEfficiencyUnits`; require `CoolingSourceType/DX` | Use only for the exact matched non-heat-pump DX object | `COP` direct; `EER` ÷ 3.412; `COP = 3.51685 ÷ kW/ton` | **MANUAL CHECK:** `SEER` is seasonal and has no exact rated-COP conversion; `Other` is undefined |
| `dx_heating_cop` | `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/AnnualHeatingEfficiencyValue` + `AnnualHeatingEfficiencyUnits = "COP"`; require `HeatingSourceType/HeatPump` | Use only for the exact matched DX heating object | COP direct | **MANUAL CHECK:** `HSPF`, `AFUE`, `Thermal Efficiency`, `Other`, and `Unknown` are not rated heating COP |
| `gas_burner_efficiency` | Furnace: `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/Furnace/ThermalEfficiency` or sibling `CombustionEfficiency`; boiler records are not targets of this measure | Prefer `ThermalEfficiency`; use `CombustionEfficiency` only under documented modeling policy | Percent ÷ 100 | **MANUAL CHECK:** combustion efficiency and `AnnualHeatingEfficiencyValue` with `AFUE` are not burner thermal efficiency |
| `electric_heating_efficiency` | `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/ElectricResistance` identifies source type; the XSD provides no matching electric-resistance efficiency value | Apply only a documented workflow/modeling assumption to exact electric heating objects | Fraction supplied by workflow | **MANUAL CHECK always:** `HeatPumpBackupAFUE` describes backup annual fuel utilization and is not electric-resistance efficiency |
| `water_to_air_*_cop` | Heating/cooling annual efficiency fields above, joined through `HVACSystem/HeatingAndCoolingSystems/HeatingSources/HeatingSource/HeatingSourceType/HeatPump/CoolingSourceID/@IDref` and `CoolingSources/CoolingSource/CoolingSourceType/DX/CondenserPlantIDs/CondenserPlantID/@IDref` | Require a resolved water-to-air coil and condenser-plant relationship | COP direct; cooling EER or kW/ton conversions as above | **MANUAL CHECK always:** no L200 water-to-air heat-pump enum exists, and source-to-OpenStudio-coil matching is consumer-owned |
| `vrf_*_cop` | `HVACSystem/HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Variable refrigerant flow"` plus source annual efficiency fields and linked `Deliveries/Delivery/DeliveryType/ZoneEquipment/FanBased/FanBasedDistributionType/FanCoil/FanCoilType = "VRF terminal units"` | Apply only to the resolved VRF outdoor-unit object | COP direct; cooling EER or kW/ton conversions as above | **MANUAL CHECK:** SEER/HSPF and other seasonal ratings are not rated COP |
| `target_object_names` | Heating/cooling source `@ID`, source `EquipmentID`, `Delivery/HeatingSourceID/@IDref`, `Delivery/CoolingSourceID/@IDref`, and component `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref` resolved to OpenStudio object names | Exact names only | Comma-separated names | **MANUAL CHECK:** an external BuildingSync-ID-to-OpenStudio-object crosswalk is required; no topology inference occurs |

## Usage

1. Resolve BuildingSync equipment records to model object names.
2. Select one metric and normalized value.
3. Run once for all named objects receiving that value.

Unsupported object/metric combinations are warned and unchanged. If none support the metric, the measure fails.
