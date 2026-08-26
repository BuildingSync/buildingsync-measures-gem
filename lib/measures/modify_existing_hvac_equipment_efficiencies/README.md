# Modify Existing HVAC Equipment Efficiencies

Sets one efficiency metric on explicitly named existing coils or VRF outdoor units. Run it once per metric/value group.

## BuildingSync mapping

| Metric | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `dx_cooling_cop` | `CoolingSource/AnnualCoolingEfficiencyValue` + units; `CoolingSourceType/DX` | Use only for matched non-heat-pump DX coils | COP direct; EER ÷ 3.412; COP = 3.51685 ÷ kW/ton | SEER requires external approximation |
| `dx_heating_cop` | Heat-pump `HeatingSource/AnnualHeatingEfficiencyValue` | Use only for matched DX heating coils | COP direct | High when units are COP |
| `gas_burner_efficiency` | `ThermalEfficiency`; fallback `CombustionEfficiency`, compatible annual efficiency | Prefer thermal, then combustion, then documented annual metric | Percent ÷ 100 | AFUE is not always identical to burner efficiency |
| `electric_heating_efficiency` | Electric resistance source; `HeatPumpBackupAFUE` candidate | Prefer explicit value; otherwise workflow may assume 1.0 | Percent ÷ 100 | Often a modeling assumption |
| `water_to_air_*_cop` | Linked WSHP/GSHP heating or cooling source annual efficiency | Require resolved heat-pump source and matching coil | COP direct; cooling conversions as above | Medium because source-to-coil matching is consumer-owned |
| `vrf_*_cop` | DX system type `Variable refrigerant flow` plus annual efficiency | Apply to exact VRF outdoor-unit names | COP direct; cooling conversions as above | Seasonal ratings are not rated COP |
| `target_object_names` | Equipment/source IDs resolved to OpenStudio names | Exact names only | Comma-separated names | No topology inference occurs |

## Usage

1. Resolve BuildingSync equipment records to model object names.
2. Select one metric and normalized value.
3. Run once for all named objects receiving that value.

Unsupported object/metric combinations are warned and unchanged. If none support the metric, the measure fails.
