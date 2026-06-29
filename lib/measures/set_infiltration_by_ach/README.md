

###### (Automatically generated documentation)

# Set Infiltration By Ach

## Description
Bulk-sets all SpaceInfiltrationDesignFlowRate objects in the model to the AirChanges/Hour calculation method. Accepts either a blower-door ACH50 value (converted to natural ACH using a user-supplied n-factor, default 20) or a natural ACH value directly. All existing infiltration objects are updated in-place; no objects are created or deleted.

## Additional Documentation

- [ASHRAE 211 Level 2 semantic mapping](docs/ASHRAE_211_L2_SEMANTIC_MAPPING.md)

## Modeler Description
Iterates getSpaceInfiltrationDesignFlowRates, sets calculation method to AirChanges/Hour, and writes natural_ach. When input_type is ACH50, natural_ach = ach_value / n_factor before writing. Applies registerAsNotApplicable when no infiltration objects exist.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Input type
Choose ACH50 for blower-door test results at 50 Pa, or ACH_natural for already-converted natural infiltration rate.
**Name:** input_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["ACH50", "ACH_natural"]


### ACH value
Numeric ACH value at the stated test pressure (ACH50) or as natural ACH, depending on input_type.
**Name:** ach_value,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### n-factor (ACH50-to-natural divisor, typically 17–20)
Used only when input_type = ACH50. natural_ACH = ACH50 / n_factor. ASHRAE/LBL default is 20 for commercial.
**Name:** n_factor,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






