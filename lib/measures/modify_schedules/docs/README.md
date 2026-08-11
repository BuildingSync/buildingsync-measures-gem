# Modify Schedules

## Purpose

Create OpenStudio schedules from BuildingSync schedule records and assign them to occupancy, lighting, electric equipment, gas equipment, HVAC availability, and optional service-water loads.

## Summary

- Each schedule argument accepts JSON or compact text.
- Every payload needs a category/target and one or more day-type intervals.
- `PartialOperationPercentage` is normalized to a `0–1` OpenStudio fraction.
- `replace_existing=true` clears matching explicit load schedules before applying the new defaults; `false` preserves matching schedules.
- The measure applies each supplied payload broadly to its model target, so the reader must select the correct BuildingSync schedule when multiple premises or systems have different profiles.

## Reference

- ASHRAE 211 L2 context: [ashrae-211-l2-semantic-mapping.md](ashrae-211-l2-semantic-mapping.md)
- Payload formats, assignments, and validation: [USAGE.md](USAGE.md)
- Implementation: [../measure.rb](../measure.rb)

## Quick Use

1. Find schedules under `/BuildingSync/Facilities/Facility/Schedules/Schedule`.
2. Select by `ScheduleCategory` and, when available, by an IDref from a premise/system (for example `OccupancyScheduleID`, `HVACScheduleID`, or `LinkedScheduleID`).
3. Build one payload from `ScheduleDetails/ScheduleDetail` records.
4. Pass the payload to the matching measure argument.

## BuildingSync Reader Mapping

| Argument | Candidate BuildingSync XML field(s) | Selection and payload rule | BuildingSyncReader function |
|---|---|---|---|
| `replace_existing` | No direct XML field | Workflow policy. Use `true` when XML schedules are authoritative; use `false` when existing model assignments should win. | TBD |
| `default_schedule_set_name` | Candidate: selected `Schedule/@ID` or a reader-generated building name | Model naming policy only; it does not select XML records. | TBD |
| `occupancy_schedule_json` | `Facility/Schedules/Schedule[ScheduleCategory='Occupied']`; prefer IDs referenced by `.../Space/OccupancyScheduleIDs/OccupancyScheduleID/@IDref` | Convert the selected schedule using the common detail mapping below. One payload is applied to occupancy loads throughout the model. | TBD |
| `lighting_schedule_json` | `Facility/Schedules/Schedule[ScheduleCategory='Lighting']`; optionally follow a system/premise `LinkedScheduleID/@IDref` | Use the linked schedule when available; otherwise select the applicable `Lighting` category record. | TBD |
| `electric_equipment_schedule_json` | `Facility/Schedules/Schedule[ScheduleCategory='Miscellaneous equipment']`; optionally follow a plug-load/premise `LinkedScheduleID/@IDref` | Route to electric equipment. Do not combine distinct process schedules unless the aggregation policy is explicit. | TBD |
| `gas_equipment_schedule_json` | Candidate schedule linked from the applicable process/gas system; categories may be `Operating`, `Miscellaneous equipment`, or `Other` | BuildingSync has no dedicated `Gas equipment` category. Select by linkage/context, then emit measure target/category `gas_equipment`. | TBD |
| `hvac_availability_schedule_json` | `Facility/Schedules/Schedule[ScheduleCategory='HVAC equipment']`; prefer IDs referenced by `.../ThermalZone/HVACScheduleIDs/HVACScheduleID/@IDref` or HVAC `LinkedPremises/.../LinkedScheduleID/@IDref` | Route to HVAC availability. Values greater than zero permit loop operation; the measure applies the result to all air loops. | TBD |
| `additional_schedules_json` | Other applicable `Schedule` records, such as `Operating`, `Heating equipment`, `Cooling equipment`, or a linked service-water schedule | Emit a JSON array. Each object must include a supported measure `target`/category such as `service_water`; reader mapping is required when the BuildingSync category is not directly supported. | TBD |

### Common `Schedule` to payload mapping

| Payload field | BuildingSync source | Rule |
|---|---|---|
| `name` | `Schedule/@ID` | Use a stable, unique name. |
| `schedule_category` or `target` | `Schedule/ScheduleCategory` | Translate to a supported target where names differ. |
| `details[].day_type` | `ScheduleDetails/ScheduleDetail/DayType` | Supported measure values include weekday, weekend/Saturday/Sunday, and holiday forms. |
| `details[].start_time` | `.../DayStartTime` | Emit `HH:MM:SS`. |
| `details[].end_time` | `.../DayEndTime` | Must be later than the start time; intervals must not overlap. |
| `details[].value_percent` | `.../PartialOperationPercentage` | Pass the percentage; the measure divides values above `1` by `100` and clamps to `0–1`. |

`SchedulePeriodBeginDate` and `SchedulePeriodEndDate` are not represented by the current payload and are ignored by this measure.

## Minimal Payload

```json
{
  "name": "Office Occupancy",
  "schedule_category": "Occupied",
  "details": [
    { "day_type": "Weekday", "start_time": "08:00:00", "end_time": "18:00:00", "value_percent": 100 },
    { "day_type": "Weekend", "start_time": "00:00:00", "end_time": "23:59:59", "value_percent": 0 }
  ]
}
```
