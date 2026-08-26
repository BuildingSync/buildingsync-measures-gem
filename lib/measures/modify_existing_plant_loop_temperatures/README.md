# Modify Existing Plant Loop Temperatures

Sets design loop exit temperature on exact, named plant loops without guessing loop purpose from names.

## BuildingSync mapping

| Argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `target_plant_loop_names` | Heating/cooling/condenser plant IDs resolved through source and delivery IDrefs | Consumer resolves the exact connected plant to model loop names | Comma-separated names | Relationship resolution is required before use |
| `design_loop_exit_temperature_c` | Cooling plant `ChilledWaterSupplyTemperature`; heating plant `HotWaterSetpointTemperature`; source setpoint candidates | Select the field belonging to the resolved plant and operating mode | °C = (°F − 32) × 5/9 | Medium; audit operating setpoint may differ from design sizing value |

## Usage

1. Resolve source/delivery plant references to an exact OpenStudio plant loop.
2. Convert the applicable supply/setpoint temperature to °C.
3. Run once for loops sharing the same design temperature.

This measure changes sizing design temperature, not operational setpoint-manager schedules.
