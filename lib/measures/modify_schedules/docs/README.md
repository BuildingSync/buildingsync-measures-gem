# Modify Schedules

## Purpose

Create OpenStudio schedules from BuildingSync schedule records and assign them to occupancy, lighting, electric equipment, gas equipment, HVAC availability, and optional service-water loads.

## Summary

- Every schedule payload is optional and empty by default. An omitted or blank payload leaves that schedule category unchanged.
- If every payload is empty, the measure reports not applicable and makes no model changes.
- Each supplied payload accepts JSON or compact text and needs one or more day-type intervals.
- BuildingSync `PartialOperationPercentage` and payload `value_percent` inputs use percentages from `0` to `100`; the measure converts them to OpenStudio fractions from `0.0` to `1.0`.
- Every payload creates a new `ScheduleRuleset`; source schedules are never renamed, edited, or removed.
- The generated name is `<source name>_modified`. If that name exists, the measure uses `_modified_2`, `_modified_3`, and so on.
- The generated schedule is assigned directly to every matching model object. Omitted categories are not changed.
- The measure applies each supplied payload broadly to its model target, so the reader must select the correct BuildingSync schedule when multiple premises or systems have different profiles.

## Reference

- ASHRAE 211 L2 context: [ashrae-211-l2-semantic-mapping.md](ashrae-211-l2-semantic-mapping.md)
- Payload formats, assignments, and validation: [USAGE.md](USAGE.md)
- Implementation: [../measure.rb](../measure.rb)

## Quick Use

1. Find schedules under `/BuildingSync/Facilities/Facility/Schedules/Schedule`.
2. Select by `ScheduleCategory` and, when available, by an IDref from a premise/system (for example `OccupancyScheduleID`, `HVACScheduleID`, or `LinkedScheduleID`).
3. Build a payload from the selected `ScheduleDetails/ScheduleDetail` records.
4. Pass it only to the matching measure argument; omit all schedule arguments that should remain unchanged.

## Arguments and Defaults

| Argument | Default | Effect |
|---|---|---|
| `occupancy_schedule_json` | empty | Empty means no occupancy changes. |
| `lighting_schedule_json` | empty | Empty means no lighting changes. |
| `electric_equipment_schedule_json` | empty | Empty means no electric-equipment changes. |
| `gas_equipment_schedule_json` | empty | Empty means no gas-equipment changes. |
| `hvac_availability_schedule_json` | empty | Empty means no air-loop availability changes. |
| `additional_schedules_json` | `[]` | An empty array means no additional schedules. |

To change only lighting, supply only `lighting_schedule_json`. If its `name` is `Office Lighting`, the measure creates `Office Lighting_modified`, leaves `Office Lighting` unchanged, and assigns the new schedule directly to every `Lights` object.

## Naming Rule

The payload `name` is the source/base schedule name, not the requested output name:

| Existing model names | Payload `name` | Generated name |
|---|---|---|
| `Office Lighting` | `Office Lighting` | `Office Lighting_modified` |
| `Office Lighting`, `Office Lighting_modified` | `Office Lighting` | `Office Lighting_modified_2` |
| No matching source object | `Audit Lighting` | `Audit Lighting_modified` |

The payload may use a BuildingSync `Schedule/@ID` as its base name when no OpenStudio source-name mapping is available. The same suffix rule applies.

## BuildingSync Reader Mapping

| Argument | Candidate BuildingSync XML field(s) | Selection and payload rule | BuildingSyncReader function |
|---|---|---|---|
| `occupancy_schedule_json` | `Facility/Schedules/Schedule[ScheduleCategory='Occupied']`; prefer IDs referenced by `.../Space/OccupancyScheduleIDs/OccupancyScheduleID/@IDref` if applicable | Convert the selected schedule using the common detail mapping below. One payload is applied to occupancy loads throughout the model. | TBD |
| `lighting_schedule_json` | `Facility/Schedules/Schedule[ScheduleCategory='Lighting']`; optionally follow a `LightingSystem`'s `LinkedScheduleID/@IDref` | Use the linked schedule when available; otherwise select the applicable `Lighting` category record. | TBD |
| `electric_equipment_schedule_json` | `Facility/Schedules/Schedule[ScheduleCategory='Miscellaneous equipment']`; optionally follow a `PlugLoad`'s `LinkedScheduleID/@IDref` | Route to electric equipment (plug load). Do not combine distinct process schedules unless the aggregation policy is explicit. | TBD |
| `gas_equipment_schedule_json` | Candidate schedule linked from `LinkedScheduleID/@IDref` of applicable `ProcessSystem[PrimaryFuel='Natural gas']`; categories may be `Other` | BuildingSync schedule has no dedicated `Gas equipment` category. | TBD |
| `hvac_availability_schedule_json` | `Facility/Schedules/Schedule[ScheduleCategory='HVAC equipment']`; prefer IDs referenced by `.../ThermalZone/HVACScheduleIDs/HVACScheduleID/@IDref` | Route to HVAC availability. Values greater than zero permit loop operation; the measure applies the result to all air loops. | TBD |
| `additional_schedules_json` | Other applicable `Schedule` records, such as `Operating`, `Heating equipment`, `Cooling equipment`, or a linked service-water schedule | Emit a JSON array. Each object must include a supported measure `target`/category such as `service_water`; reader mapping is required when the BuildingSync category is not directly supported. | TBD |

### Common `Schedule` to payload mapping

| Payload field | BuildingSync source | Rule |
|---|---|---|
| `name` | `Schedule/@ID`, or the linked OpenStudio source schedule name when available | This is the base name. The measure creates `<name>_modified`, adding `_2`, `_3`, etc. when needed. |
| `schedule_category` or `target` | `Schedule/ScheduleCategory` | Translate to a supported target where names differ. |
| `details[].day_type` | `ScheduleDetails/ScheduleDetail/DayType` | Supported measure values include weekday, weekend/Saturday/Sunday, and holiday forms. |
| `details[].start_time` | `.../DayStartTime` | Emit `HH:MM:SS`. |
| `details[].end_time` | `.../DayEndTime` | Must be later than the start time; intervals must not overlap. |
| `details[].value_percent` | `.../PartialOperationPercentage` | Use a percentage from `0` to `100`. The measure divides it by `100` and clamps the resulting fraction to `0.0–1.0`. |

`SchedulePeriodBeginDate` and `SchedulePeriodEndDate` are not represented by the current payload and are ignored by this measure.

## Percentage Values

- Use `value_percent` or `partialoperationpercentage` for BuildingSync percentages: `0` means off, `50` means half output, and `100` means full output.
- Do not use `0.5` with `value_percent` to mean 50%; it means 0.5% and becomes `0.005` internally.
- The generic fields `fraction` or `value` may use an OpenStudio fraction from `0.0` to `1.0`, but `value_percent` is recommended for direct BuildingSync translation.

## Example: Change Only Lighting

The reader selects a BuildingSync `Schedule` with `ScheduleCategory = Lighting` and produces this payload:

```json
{
  "name": "Existing Office Lighting Schedule",
  "schedule_category": "Lighting",
  "details": [
    { "day_type": "Weekday", "start_time": "00:00:00", "end_time": "07:00:00", "value_percent": 10 },
    { "day_type": "Weekday", "start_time": "07:00:00", "end_time": "18:00:00", "value_percent": 100 },
    { "day_type": "Weekday", "start_time": "18:00:00", "end_time": "24:00:00", "value_percent": 10 },
    { "day_type": "Weekend", "start_time": "00:00:00", "end_time": "24:00:00", "value_percent": 10 },
    { "day_type": "Holiday", "start_time": "00:00:00", "end_time": "24:00:00", "value_percent": 10 }
  ]
}
```

This payload creates `Existing Office Lighting Schedule_modified`; it does not alter a source schedule named `Existing Office Lighting Schedule`.

The equivalent OSW step can use the compact form to avoid escaping JSON:

```json
{
  "measure_dir_name": "modify_schedules",
  "arguments": {
    "lighting_schedule_json": "name=Existing Office Lighting Schedule;schedule_category=Lighting;Weekday|00:00:00|07:00:00|10;Weekday|07:00:00|18:00:00|100;Weekday|18:00:00|24:00:00|10;Weekend|00:00:00|24:00:00|10;Holiday|00:00:00|24:00:00|10"
  }
}
```

All other payload arguments are omitted, so occupancy, electric equipment, gas equipment, HVAC availability, and service-water schedules remain unchanged. Every lighting load is assigned `Existing Office Lighting Schedule_modified`; the measure does not scope it to one space or premise.
