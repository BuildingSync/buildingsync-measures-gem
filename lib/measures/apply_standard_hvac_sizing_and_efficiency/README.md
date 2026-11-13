

###### (Automatically generated documentation)

# Apply Standard HVAC Sizing And Efficiency

## Description
Sizes existing HVAC with a sizing run and applies prototype assumptions and 90.1 efficiencies.

## Modeler Description
Mirrors the add_hvac tail of OpenstudioStandards::CreateTypical.create_typical_building_from_model (openstudio-standards 0.8.x): PRM sizing parameters, sizing run, multizone VAV outdoor-air sizing, prototype HVAC assumptions, HVAC efficiency standard, NIST infiltration schedules, and thermostat night-cycle control. Requires the building standards type and climate zone that create_typical_building_from_model sets.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Standards Template

**Name:** standards_template,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Apply NIST Infiltration Schedules

**Name:** add_infiltration_schedules,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false
