# Modify Existing Plant Loop Temperatures

Sets design loop exit temperature on exact, named plant loops without guessing loop purpose from names.

## BuildingSync mapping

| Argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `target_plant_loop_names` | `HVACSystem/Plants/HeatingPlants/HeatingPlant/@ID`, `CoolingPlants/CoolingPlant/@ID`, or `CondenserPlants/CondenserPlant/@ID`, resolved through `HeatingSourceType/SourceHeatingPlantID/@IDref`, `CoolingSourceType/CoolingPlantID/@IDref`, `Delivery/ReheatPlantID/@IDref`, or `DX/CondenserPlantIDs/CondenserPlantID/@IDref` | Resolve the exact connected plant to an OpenStudio plant-loop name | Comma-separated names | **MANUAL CHECK always:** BuildingSync plant IDs identify equipment records, not OpenStudio loop names; an external crosswalk is required |
| `design_loop_exit_temperature_c` — heating | `HVACSystem/Plants/HeatingPlants/HeatingPlant/Boiler/BoilerLWT` | Use only for the resolved hot-water boiler/loop operating mode | °C = (°F − 32) × 5/9 | **MANUAL CHECK:** `BoilerLWT` is a supplied-water/setpoint value; the measure changes sizing design loop exit temperature, not an operational setpoint-manager schedule |
| `design_loop_exit_temperature_c` — cooling | `HVACSystem/Plants/CoolingPlants/CoolingPlant/Chiller/ChilledWaterSupplyTemperature` | Use only for the resolved chilled-water chiller/loop operating mode | °C = (°F − 32) × 5/9 | **MANUAL CHECK:** supplied-water temperature and sizing design loop exit temperature are not necessarily equivalent |
| MANUAL CHECK | Condenser loops, non-boiler heating plants, multiple plants with different setpoints, or records lacking explicit IDREFs and temperature fields | Establish loop purpose, design basis, and one intended sizing temperature outside the schema mapping | Manual engineering review | Required for every non-direct case |

## Usage

1. Resolve source/delivery plant references to an exact OpenStudio plant loop.
2. Convert the applicable supply/setpoint temperature to °C.
3. Run once for loops sharing the same design temperature.

This measure changes sizing design temperature, not operational setpoint-manager schedules.
