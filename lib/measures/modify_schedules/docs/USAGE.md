# Modify Schedules — Measure Documentation

## Overview

The **Modify Schedules** measure creates or replaces OpenStudio schedule objects from BuildingSync-aligned schedule payloads and automatically binds them to occupancy, lighting, plug load, gas equipment, process loads, HVAC availability, and other building end uses.

This measure enables users to:
- Import standardized schedule data from BuildingSync XML audit documents
- Apply occupancy, lighting, equipment, and HVAC control schedules to OpenStudio models
- Apply dedicated gas equipment schedules through the default schedule set
- Maintain BuildingSync-native schedule semantics (day types, partial operation percentages)
- Extend scheduling to arbitrary load categories (gas equipment, service water, etc.)

## BuildingSync Mapping

BuildingSync schedule data is organized using the `ScheduleDetail` structure, which defines fractional value profiles across different day types and operating hours.

### BuildingSync Payload Structure

Each schedule payload follows this pattern:

```json
{
  "name": "Schedule Name",
  "schedule_category": "ScheduleCategory",
  "details": [
    {
      "day_type": "Weekday|Weekend|Holiday",
      "start_time": "HH:MM:SS",
      "end_time": "HH:MM:SS",
      "value_percent": 0–100
    }
  ]
}
```

### Supported ScheduleCategory Values

BuildingSync categories map to OpenStudio schedule targets as follows:

| BuildingSync Category | OpenStudio Target | Load Type | Applied To |
|---|---|---|---|
| `Occupied`, `Occupancy`, `People`, `NumberOfPeople` | `occupancy` | Occupant presence | People objects, internal loads |
| `Lighting`, `Lights` | `lighting` | Illumination | Lights objects |
| `Miscellaneous equipment`, `Plug load`, `Electric equipment` | `electric_equipment` | Plug loads | ElectricEquipment objects |
| `HVAC equipment`, `HVAC availability`, `Availability schedule` | `hvac_availability` | System availability | AirLoopHVAC objects |
| `Gas equipment` | `gas_equipment` | Gas loads | GasEquipment objects |
| `Service water`, `Service water heating`, `Water use`, `SHW`, `DHW` | `service_water` | Hot water demand | WaterUseEquipment objects |

### Day Type Semantics

BuildingSync defines three day type categories that map to OpenStudio schedule rules:

| Day Type | OpenStudio Mapping | Schedule Rule |
|---|---|---|
| `Weekday` | Default schedule day (Monday–Friday) | Default ScheduleDay |
| `Weekend` | Saturday rule | Saturday ScheduleDay |
| `Holiday` | Holiday rule | Holiday ScheduleDay |

If no Saturday or Sunday intervals are specified, those days default to the weekday profile.

### Values and Fractional Normalization

- BuildingSync values are specified as percentages (0–100)
- The measure automatically normalizes values to OpenStudio's 0.0–1.0 fraction range
- Values exceeding 1.0 are clamped to 1.0; negative values are clamped to 0.0
- Design-day (summer/winter) schedules default to the maximum value across all intervals for that schedule

## Input Arguments

### Required Arguments

#### 1. **Replace Existing Matching Schedules** (`replace_existing`)
- **Type:** Boolean
- **Default:** `true`
- **Description:** When `true`, overwrites existing ScheduleRulesets with matching names. When `false`, preserves and reuses existing schedules.
- **Use Case:** Set to `false` if you want to augment rather than replace existing schedules.

#### 2. **Default Schedule Set Name** (`default_schedule_set_name`)
- **Type:** String
- **Default:** `"Modified Schedule Set"`
- **Description:** Name of the building-level DefaultScheduleSet that receives imported occupancy, lighting, and equipment schedules. This set is applied to all space types to ensure consistent internal load scheduling.
- **Note:** If a default schedule set already exists, it will be updated with this name.

#### 3. **Occupancy Schedule Payload** (`occupancy_schedule_json`)
- **Type:** String (JSON or Compact Text)
- **Default:** Small office weekday occupancy profile (6am–6pm peak, low shoulders)
- **Description:** BuildingSync payload defining occupancy fraction schedule. Target category auto-detected as occupancy.
- **Format:** See [Payload Format](#payload-formats) section below.

#### 4. **Lighting Schedule Payload** (`lighting_schedule_json`)
- **Type:** String (JSON or Compact Text)
- **Default:** Small office weekday lighting profile (ramps around occupancy, flat 18% off-hours)
- **Description:** BuildingSync payload for lighting fraction schedule. Target category auto-detected as lighting.
- **Format:** See [Payload Format](#payload-formats) section below.

#### 5. **Plug Load Schedule Payload** (`electric_equipment_schedule_json`)
- **Type:** String (JSON or Compact Text)
- **Default:** Small office weekday equipment profile (50% baseline, 100% peak, 20% off-hours)
- **Description:** BuildingSync payload for plug-load fraction schedule. Target category auto-detected as electric equipment.
- **Format:** See [Payload Format](#payload-formats) section below.

#### 6. **Gas Equipment Schedule Payload** (`gas_equipment_schedule_json`)
- **Type:** String (JSON or Compact Text)
- **Default:** Empty
- **Description:** Dedicated BuildingSync payload for gas equipment schedules. This avoids having to pass gas equipment through `additional_schedules_json`.
- **Format:** See [Payload Format](#payload-formats) section below.

#### 7. **HVAC Availability Schedule Payload** (`hvac_availability_schedule_json`)
- **Type:** String (JSON or Compact Text)
- **Default:** Small office building hours (6am–8pm weekday, 0% weekend/holiday)
- **Description:** BuildingSync payload for HVAC system availability. Applied to all air loops. Values of 0 disable system operation; values > 0 permit operation.
- **Format:** See [Payload Format](#payload-formats) section below.

#### 8. **Additional Schedule Payloads** (`additional_schedules_json`)
- **Type:** String (JSON array or Compact Text)
- **Default:** `"[]"` (empty array)
- **Description:** JSON array of additional schedule payloads for extensible categories that are not already exposed as dedicated arguments, such as service water heating. Each payload must include a valid `schedule_category` or `target` field.
- **Example:**
  ```json
  [
    {
      "name": "Gas Equipment Schedule",
      "schedule_category": "Gas equipment",
      "details": [...]
    },
    {
      "name": "Service Water Schedule",
      "schedule_category": "Service water heating",
      "details": [...]
    }
  ]
  ```
- **Format:** See [Payload Format](#payload-formats) section below.

## Payload Formats

The measure accepts schedule payloads in two formats:

### Format 1: JSON (BuildingSync Native)

Standard JSON object with metadata and details array:

```json
{
  "name": "Office Occupancy",
  "schedule_category": "Occupied",
  "details": [
    { "day_type": "Weekday", "start_time": "06:00:00", "end_time": "07:00:00", "value_percent": 11 },
    { "day_type": "Weekday", "start_time": "07:00:00", "end_time": "08:00:00", "value_percent": 21 },
    { "day_type": "Weekday", "start_time": "08:00:00", "end_time": "12:00:00", "value_percent": 100 },
    { "day_type": "Weekend", "start_time": "00:00:00", "end_time": "23:59:59", "value_percent": 0 },
    { "day_type": "Holiday", "start_time": "00:00:00", "end_time": "23:59:59", "value_percent": 0 }
  ]
}
```

**Advantages:**
- Full expressivity of JSON data model
- Integrates seamlessly with BuildingSync XML sources
- Clear, explicit structure

**Field Names (case-insensitive aliases supported):**
- Schedule metadata: `name` (or `schedule_name`), `schedule_category` (or `category`, `target`)
- Detail intervals: `day_type`, `start_time` (or `daystarttime`), `end_time` (or `dayendtime`), `value_percent` (or `partialoperationpercentage`, `value`, `fraction`)

### Format 2: Compact Text (Escaping-Safe)

Semicolon-separated records with pipe-delimited intervals, optimized for measure default values:

```
name=Office Occupancy;schedule_category=Occupied;Weekday|06:00:00|07:00:00|11;Weekday|07:00:00|08:00:00|21;Weekday|08:00:00|12:00:00|100;Weekend|00:00:00|23:59:59|0;Holiday|00:00:00|23:59:59|0
```

**Structure:**
- Metadata: key=value pairs (name, schedule_category, etc.)
- Intervals: day_type|start_time|end_time|value_percent
- Separator: semicolon (`;`)
- Within intervals: pipe (`|`)

**Parsing Rules:**
1. Records are split by `;`
2. Records containing `=` and no `|` are treated as metadata key-value pairs
3. Records with pipe-delimited structure are treated as day-type intervals
4. All timestamps must be in HH:MM:SS format (00:00:00 to 23:59:59)
5. Values are percentages (0–100); division by 100 is automatic

**Example with all three day types:**
```
name=Lighting;schedule_category=Lighting;Weekday|00:00:00|05:00:00|18;Weekday|05:00:00|08:00:00|42;Weekday|08:00:00|22:00:00|90;Weekend|00:00:00|23:59:59|18;Holiday|00:00:00|23:59:59|18
```

**Advantages:**
- No escaping required (safe for measure default values and CLI arguments)
- Compact and human-readable
- Suitable for programmatic payload construction

## Model Binding Behavior

Once schedules are imported, the measure applies them to the model as follows:

### Occupancy Schedules
- Added to building-level DefaultScheduleSet as occupancy schedule
- Applied to all People objects via the default schedule set
- If `replace_existing=true`, explicit people activity schedules are cleared

### Lighting Schedules
- Added to building-level DefaultScheduleSet as lighting schedule
- Applied to all Lights objects via the default schedule set
- If `replace_existing=true`, explicit lighting schedules are cleared

### Plug Load Schedules
- Added to building-level DefaultScheduleSet as electric equipment schedule
- Applied to ElectricEquipment objects via the default schedule set
- If `replace_existing=true`, explicit equipment schedules are cleared

### Gas Equipment Schedules
- Added to building-level DefaultScheduleSet as gas equipment schedule
- Applied to GasEquipment objects via the default schedule set

### HVAC Availability Schedules
- Bound directly to **each AirLoopHVAC** object in the model
- Controls loop availability; 0 = disabled, > 0 = operational
- Applied regardless of DefaultScheduleSet (air loops don't use default schedules)

### Additional Schedules
- If included in `additional_schedules_json`, schedules are created for extensible categories such as service water
- WaterUseEquipment objects automatically reference service-water schedules

### Design Days
- Summer and winter design-day schedules default to the maximum fraction value across all intervals

## Common Use Cases

### Use Case 1: Import Small Office Schedules from BuildingSync

**Scenario:** You have audit data for a 5,000 ft² office and want to apply realistic occupancy, lighting, and plug load profiles.

**Payload Construction (Compact Format):**
```
occupancy_schedule_json = "name=Office Occupancy;schedule_category=Occupied;Weekday|06:00:00|22:00:00|100;Weekend|00:00:00|23:59:59|0"
lighting_schedule_json = "name=Office Lighting;schedule_category=Lighting;Weekday|06:00:00|22:00:00|90;Weekend|00:00:00|23:59:59|10"
electric_equipment_schedule_json = "name=Office Equipment;schedule_category=Miscellaneous equipment;Weekday|08:00:00|18:00:00|100;Weekend|00:00:00|23:59:59|20"
hvac_availability_schedule_json = "name=HVAC Schedule;schedule_category=HVAC availability;Weekday|06:00:00|22:00:00|100;Weekend|00:00:00|23:59:59|0"
```

**Expected Result:** 
- 4 ScheduleRulesets created and bound to all occupancy, lighting, and equipment loads
- All air loops set to disabled on weekends
- Model ready for annual simulation with realistic operational profiles

### Use Case 2: Add Dedicated Gas Equipment and Service Water Schedules

**Scenario:** Your building has natural gas heating equipment and service water usage that need scheduling.

**Payloads:**

Dedicated gas equipment payload:
```text
gas_equipment_schedule_json = "name=Gas Equipment Schedule;schedule_category=Gas equipment;Weekday|06:00:00|22:00:00|80;Weekend|00:00:00|23:59:59|20"
```

Additional schedules JSON for service water:
```json
[
  {
    "name": "Service Water Schedule",
    "schedule_category": "Service water heating",
    "details": [
      { "day_type": "Weekday", "start_time": "06:00:00", "end_time": "22:00:00", "value_percent": 100 },
      { "day_type": "Weekend", "start_time": "00:00:00", "end_time": "23:59:59", "value_percent": 30 }
    ]
  }
]
```

**Expected Result:**
- Dedicated gas equipment schedule bound to the default schedule set
- Additional service-water schedule created and bound to WaterUseEquipment objects
- Model now covers full end-use spectrum (occupancy, lighting, electric, gas, water)

### Use Case 3: Override Existing Schedules in an Existing Model

**Scenario:** Your baseline model already has occupancy profiles, but you want to replace them with audit-based data.

**Configuration:**
- Set `replace_existing = true`
- Provide new occupancy/lighting/equipment payloads
- Existing explicit schedules on People, Lights, and ElectricEquipment objects are cleared
- New schedules are created and applied via DefaultScheduleSet (automatic consistency)

**Result:**
- Old schedules remain as orphaned objects (referenceable by name, but not actively used)
- New schedules take effect immediately; ready for resimulation

## Error Handling

The measure validates inputs and reports errors as follows:

### Validation Errors (Return `false`, halt measure)

| Error | Cause | Recovery |
|---|---|---|
| "must include a non-empty 'details' array" | Payload missing or empty details | Ensure schedule payload includes at least one interval |
| "does not map to a supported OpenStudio target" | Invalid schedule_category | Check category name against [Supported ScheduleCategory Values](#supported-schedulecategory-values) table |
| "missing day type, start time, end time, or value" | Incomplete schedule detail record | Ensure all required fields are present in each detail |
| "has an invalid time format. Use HH:MM:SS." | Non-standard time string | Use HH:MM:SS format; leading zeros required (e.g., `06:00:00`, not `6:00:00`) |
| "end_time is not later than start_time" | Time range invalid | Ensure start_time < end_time for each interval |
| "has overlapping or out-of-order intervals" | Intervals conflict chronologically | Sort intervals by start time; ensure no gaps/overlaps |
| "contains an invalid compact record" | Malformed compact-text interval | Verify pipe-delimited format: `DayType\|HH:MM:SS\|HH:MM:SS\|Value` |

### Warnings (Logged; measure continues)

| Warning | Cause | Impact |
|---|---|---|
| "Keeping existing schedule 'Name'" | Schedule already exists, `replace_existing=false` | Existing schedule reused; new payload ignored |
| "unsupported day type '...'" | Day type not recognized (e.g., typo in `Weekdays`) | Interval ignored; partial schedule applied |

### Not Applicable Conditions (Return `true`, no changes)

| Condition | Trigger |
|---|---|
| "No schedule payloads were provided" | All payload arguments are empty or whitespace |

## Testing & Validation

The measure includes comprehensive integration tests:

- **Test 1:** Default payloads applied to baseline model
  - Validates: Schedule creation, interval parsing, day-type routing
  - Expected: 4 schedules created, 3+ internal load objects scheduled

- **Test 2:** Custom JSON payloads with overrides
  - Validates: JSON parsing, case-insensitive category mapping, existing-schedule preservation
  - Expected: Payloads parsed without errors; existing schedules retained when `replace_existing=false`

To run tests locally:

```bash
cd /repo
RUN_OPENSTUDIO_INTEGRATION=1 pytest tests/test_measure_authoring.py -k "modify_schedules" -v
```

## Technical Notes

### Time Representation

- All times are stored as total seconds from midnight (0–86,400)
- OpenStudio `Time` objects are constructed from (days=0, hours, minutes, seconds) components
- Timestamps are clamped to 23:59:59 maximum; 24:00:00 is converted to 23:59:59

### Schedule Type Limits

- All imported schedules are assigned to a `Fraction` schedule type limit (0.0–1.0, continuous, dimensionless)
- If no Fraction type exists in the model, one is created automatically

### Design Days

- Summer and winter design-day values default to **max(all interval values)**
- This ensures conservative autosizing calculations

### Air Loop Binding

- HVAC availability schedules are bound directly to AirLoopHVAC objects, bypassing DefaultScheduleSet
- Each air loop independently references the schedule
- Changing air-loop availability does not affect occupancy/lighting/equipment scheduling

## Extensibility

The measure architecture supports custom schedule categories via:

1. **Existing category aliases:** New day types or OpenStudio target names can be added to the `normalize_target` function
2. **Additional payloads:** Arbitrary JSON objects can be passed via `additional_schedules_json` with novel `schedule_category` values
3. **Measure customization:** Forking the measure and extending the binding logic to handle new OpenStudio object types (e.g., ChilledBeams, Humidifiers)

## References

- **BuildingSync Specification:** [NREL BuildingSync Documentation](https://buildingsync.net/)
- **OpenStudio ScheduleRuleset:** [OpenStudio SDK Class Reference](https://openstudio.net/docs/api/)
- **ASHRAE Schedule Standards:** [ASHRAE 90.1 Appendix A](https://www.ashrae.org/technical-resources/bookstore/ashrae-90-1)

---

**Measure Version:** 1.0  
**Author:** OpenStudio MCP  
**Last Updated:** April 2026
