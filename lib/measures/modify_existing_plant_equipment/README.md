# Modify Existing Plant Equipment

Sets one capacity or efficiency property on exact, named hot-water boilers or electric EIR chillers.

## BuildingSync mapping

| Property | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `boiler_capacity_kw` | `HeatingPlant/Boiler/Capacity` + `CapacityUnits`; fallback linked heating source capacity | Prefer boiler nameplate capacity | Convert declared units to kW | Nameplate capacity may differ from design load |
| `boiler_thermal_efficiency` | `Boiler/ThermalEfficiency`; fallback `CombustionEfficiency`, compatible annual efficiency | Prefer thermal efficiency | Percent ÷ 100 | AFUE fallback is approximate |
| `chiller_capacity_tons` | `CoolingPlant/Chiller/Capacity` + `CapacityUnits`; fallback linked cooling source capacity | Prefer chiller record | Convert declared units to refrigeration tons | High when capacity units are present |
| `chiller_reference_cop` | `Chiller/AnnualCoolingEfficiencyValue` + units | Prefer COP; convert EER or kW/ton | EER ÷ 3.412; COP = 3.51685 ÷ kW/ton | Seasonal ratings need workflow policy |
| `target_plant_equipment_names` | Plant/equipment IDs resolved to model names | Exact names only | Comma-separated names | Consumer owns ID resolution |

## Usage

1. Resolve selected BuildingSync boiler/chiller records to OpenStudio names.
2. Select one property and converted value.
3. Run once for equipment sharing that value.

The measure preserves autosizing only when a capacity property is not invoked.
