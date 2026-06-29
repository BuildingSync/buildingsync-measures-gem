
###### (Automatically generated documentation)

# Set Envelope Construction R-Values and U-Values

## Description
Sets target R-values (or U-values) for exterior walls, roofs, and floors by modifying insulation material thickness in construction assemblies. Accepts either R-value targets or U-value targets, which are automatically converted (R = 1/U).

## Additional Documentation

- [ASHRAE 211 Level 2 semantic mapping](docs/ASHRAE_211_L2_SEMANTIC_MAPPING.md)

## Modeler Description
Modifies construction layer insulation thickness to achieve target overall R-values for exterior opaque surfaces. Supports both R-value and U-value inputs. When U-values are provided, they are converted to R-values. Operates on StandardOpaqueMaterial layers within exterior wall, roof, and floor constructions.

## Measure Type
ModelMeasure

## Taxonomy

## Arguments

### Exterior Wall Target R-value
Target overall R-value for exterior walls (m²K/W). Leave 0 to skip walls.
**Name:** wall_target_rvalue,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Exterior Wall Target U-value (Alternative)
Target overall U-value for exterior walls (W/m²K). Automatically converted to R-value (R = 1/U). Leave 0 to use R-value target instead.
**Name:** wall_target_uvalue,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Roof/Ceiling Target R-value
Target overall R-value for roofs and ceilings (m²K/W). Leave 0 to skip roofs.
**Name:** roof_target_rvalue,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Roof/Ceiling Target U-value (Alternative)
Target overall U-value for roofs and ceilings (W/m²K). Automatically converted to R-value (R = 1/U). Leave 0 to use R-value target instead.
**Name:** roof_target_uvalue,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Floor/Foundation Target R-value
Target overall R-value for floors and foundations (m²K/W). Leave 0 to skip floors.
**Name:** floor_target_rvalue,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Floor/Foundation Target U-value (Alternative)
Target overall U-value for floors and foundations (W/m²K). Automatically converted to R-value (R = 1/U). Leave 0 to use R-value target instead.
**Name:** floor_target_uvalue,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


