

###### (Automatically generated documentation)

# Modify Hvac

## Description
L2 HVAC audit translation measure. Modifies or synthesizes HVAC across all 18 BuildingSync PrincipalHVACSystemType enums plus a radiant extension (19 types). Applies audit efficiencies/COPs, supply air temps, economizer controls, ERV effectiveness, and metadata. Synthesizes missing systems via openstudio-standards.

## Modeler Description
Per-type dispatcher covering BuildingSync PrincipalHVACSystemType values. Plant-level args apply globally; zone-equipment args scoped by target_zone_names.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### HVAC System Type
BuildingSync PrincipalHVACSystemType (snake_cased) + radiant extension. 'other', 'unknown', 'existing_unknown_mixed_system' leave HVAC unchanged.
**Name:** hvac_system_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["packaged_terminal_air_conditioner", "packaged_terminal_heat_pump", "four_pipe_fan_coil_unit", "packaged_rooftop_air_conditioner", "packaged_rooftop_heat_pump", "packaged_rooftop_vav_hot_water_reheat", "packaged_rooftop_vav_electric_reheat", "vav_with_hot_water_reheat", "vav_with_electric_reheat", "warm_air_furnace", "ventilation_only", "dedicated_outdoor_air_system", "water_loop_heat_pump", "ground_source_heat_pump", "vrf_terminal_unit", "chilled_beam", "radiant_system", "other", "unknown", "existing_unknown_mixed_system", "vav_with_boiler_and_central_chiller", "fan_coil_with_central_plant"]


### Target Air Loop Name
Exact air loop name. Blank = all.
**Name:** target_air_loop_name,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Target Zone Names
Comma-separated thermal zone names for zone-equipment scoping. Blank = all. Plant-level args still apply globally.
**Name:** target_zone_names,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Synthesize Missing Equipment
If true, use openstudio-standards to add the system when absent, then tune.
**Name:** synthesize_if_missing,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Economizer Control Type
OA economizer strategy (air-loop types only).
**Name:** economizer_control_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["NoEconomizer", "FixedDryBulb", "FixedEnthalpy", "DifferentialDryBulb", "DifferentialEnthalpy", "ElectronicEnthalpy"]


### Econ High Limit DB (C)
Dry-bulb lockout (C).
**Name:** economizer_high_limit_dry_bulb_temperature_c,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Econ High Limit Enthalpy (J/kg)
Enthalpy lockout (J/kg).
**Name:** economizer_high_limit_enthalpy_j_kg,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Central Cooling SAT (C)
Air-loop cooling design SAT.
**Name:** central_cooling_supply_air_temperature_c,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Central Heating SAT (C)
Air-loop heating design SAT.
**Name:** central_heating_supply_air_temperature_c,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### DOAS SAT (C)
DOAS neutral-air supply temp (C). Used by DOAS / ventilation_only / chilled_beam.
**Name:** doas_supply_air_temperature_c,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### ERV Sensible Effectiveness
Target sensible effectiveness (0-1). 0 = leave unchanged.
**Name:** erv_sensible_effectiveness,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### ERV Latent Effectiveness
Target latent effectiveness (0-1). 0 = leave unchanged.
**Name:** erv_latent_effectiveness,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Design Heating Capacity (kW)
Fallback for boiler capacity.
**Name:** design_heating_capacity_kw,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Design Cooling Capacity (tons)
Fallback for chiller capacity.
**Name:** design_cooling_capacity_tons,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Boiler Capacity (kW)
0 = autosize preserved.
**Name:** boiler_capacity_kw,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Boiler Efficiency
BoilerHotWater nominal thermal efficiency (0-1).
**Name:** boiler_nominal_thermal_efficiency,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Chiller Capacity (tons)
0 = autosize preserved.
**Name:** chiller_capacity_tons,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Chiller COP
ChillerElectricEIR reference COP (>0).
**Name:** chiller_reference_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### DX Cooling COP
CoilCoolingDX rated COP. Used by PTAC / PSZ-AC / Pkg RTU VAV (both).
**Name:** dx_cooling_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Gas Furnace Efficiency
CoilHeatingGas burner efficiency (0-1).
**Name:** gas_furnace_thermal_efficiency,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HP Cooling COP
DX HP / VRF / WSHP rated cooling COP.
**Name:** heat_pump_cooling_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HP Heating COP
DX HP / VRF / WSHP rated heating COP.
**Name:** heat_pump_heating_cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Backup Resistance Efficiency
CoilHeatingElectric efficiency (0-1).
**Name:** backup_resistance_efficiency,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Radiant CHW Supply (C)
Low-temp radiant CHW supply.
**Name:** radiant_chilled_water_supply_temperature_c,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Radiant HW Supply (C)
Low-temp radiant HW supply.
**Name:** radiant_hot_water_supply_temperature_c,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Chilled Beam Primary Air Fraction
Metadata only.
**Name:** chilled_beam_primary_air_fraction,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Year Installed
Audit metadata (1950-2100).
**Name:** year_installed,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Condition Assessment
Audit metadata.
**Name:** condition_assessment,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["excellent", "good", "average", "poor", "unknown"]


### Control Type (Audit)
Audit metadata.
**Name:** control_type_audit,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["pneumatic", "direct_digital_control", "unknown"]


### Zone Control Strategy
Audit metadata.
**Name:** zone_control_strategy,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["core_perimeter", "all_zones", "space_types"]


### Preserve Existing Sizing
If true, keep autosized capacities; only apply efficiencies/COPs.
**Name:** preserve_existing_sizing,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false






