# Modify Existing Plant Equipment

Sets one capacity or efficiency property on exact, named hot-water boilers or electric EIR chillers.

## BuildingSync mapping

| Property | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `boiler_capacity_kw` | `HVACSystem/Plants/HeatingPlants/HeatingPlant/Boiler/Capacity` + sibling `CapacityUnits` | Use capacity on the exact boiler record; do not substitute `HeatingSource/Capacity` without documented equivalence | Convert XSD units (`W`, `kW`, `MW`, `Btu/hr`, `kBtu/hr`, `MMBtu/hr`, `Cooling ton`, etc.) to kW | **MANUAL CHECK:** missing/`Other` units, linked-source fallback, and nameplate-versus-model design capacity |
| `boiler_thermal_efficiency` | `HVACSystem/Plants/HeatingPlants/HeatingPlant/Boiler/ThermalEfficiency`; secondary candidate `CombustionEfficiency` | Prefer thermal efficiency | Percent ÷ 100 | **MANUAL CHECK:** combustion efficiency and annual `AFUE` are not boiler thermal efficiency |
| `chiller_capacity_tons` | `HVACSystem/Plants/CoolingPlants/CoolingPlant/Chiller/Capacity` + sibling `CapacityUnits` | Use capacity on the exact chiller record | Convert declared units to refrigeration tons | **MANUAL CHECK:** missing/`Other` units or substitution from linked `CoolingSource/Capacity` |
| `chiller_reference_cop` | `HVACSystem/Plants/CoolingPlants/CoolingPlant/Chiller/AnnualCoolingEfficiencyValue` + `AnnualCoolingEfficiencyUnits` | Use `COP` directly; convert only rated `EER` or `kW/ton` | `EER` ÷ 3.412; `COP = 3.51685 ÷ kW/ton` | **MANUAL CHECK:** `SEER` is seasonal, `Other` is undefined, and reported conditions may differ from the OpenStudio reference point |
| `target_plant_equipment_names` | `HVACSystem/Plants/HeatingPlants/HeatingPlant/@ID` or `HVACSystem/Plants/CoolingPlants/CoolingPlant/@ID`; plant `EquipmentID`; `HeatingSourceType/SourceHeatingPlantID/@IDref`; `CoolingSourceType/CoolingPlantID/@IDref`; plant `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref` | Resolve exact BuildingSync plant records to OpenStudio boiler/chiller names | Comma-separated names | **MANUAL CHECK always:** BuildingSync IDs are not OpenStudio object names; an external crosswalk is required |

## Usage

1. Resolve selected BuildingSync boiler/chiller records to OpenStudio names.
2. Select one property and converted value.
3. Run once for equipment sharing that value.

The measure preserves autosizing only when a capacity property is not invoked.
