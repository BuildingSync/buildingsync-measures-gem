

###### (Automatically generated documentation)

# Modify Schedules

## Description
Create or replace OpenStudio schedules from BuildingSync-aligned schedule detail payloads and bind them to occupancy, lighting, plug loads, gas equipment, HVAC availability, and optional additional end uses.

## Additional Documentation

- [ASHRAE 211 Level 2 semantic mapping](docs/ASHRAE_211_L2_SEMANTIC_MAPPING.md)

## Modeler Description
Accepts BuildingSync-style schedule payloads with day types, start/end times, and partial operation percentages. Builds ScheduleRulesets, assigns them to building and space type default schedule sets, resets explicit internal load schedules when requested, applies HVAC availability schedules to air loops, supports a dedicated gas equipment schedule, and retains extensible additional targets such as service water.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Replace Existing Matching Schedules
Overwrite existing ScheduleRulesets with matching names when true. Keep matching schedules when false.
**Name:** replace_existing,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Default Schedule Set Name
Name of the building-level default schedule set that receives imported occupancy, lighting, and equipment schedules.
**Name:** default_schedule_set_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Occupancy Schedule Payload
BuildingSync schedule payload. Supports either JSON or compact BuildingSync text using semicolon-separated records like name=...;schedule_category=Occupied;Weekday|06:00:00|07:00:00|11.
**Name:** occupancy_schedule_json,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Lighting Schedule Payload
BuildingSync schedule payload for lighting. Supports JSON or compact semicolon-separated BuildingSync text.
**Name:** lighting_schedule_json,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Plug Load Schedule Payload
BuildingSync schedule payload for plug or electric equipment schedules. Supports JSON or compact semicolon-separated BuildingSync text.
**Name:** electric_equipment_schedule_json,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Gas Equipment Schedule Payload
BuildingSync schedule payload for gas equipment schedules. Supports JSON or compact semicolon-separated BuildingSync text.
**Name:** gas_equipment_schedule_json,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### HVAC Availability Schedule Payload
BuildingSync schedule payload for HVAC availability schedules. Supports JSON or compact semicolon-separated BuildingSync text.
**Name:** hvac_availability_schedule_json,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Additional Schedule Payloads
JSON array or compact semicolon-separated payloads for extensible categories such as service water or other custom schedules.
**Name:** additional_schedules_json,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false






