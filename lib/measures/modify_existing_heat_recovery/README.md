# Modify Existing Heat Recovery

Sets sensible or latent effectiveness on exact, named sensible-and-latent air-to-air heat exchangers.

## BuildingSync mapping

| Argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `target_heat_exchanger_names` | `Systems/HeatRecoverySystems/HeatRecoverySystem/@ID`; `HeatRecoverySystem/EquipmentID`; `LinkedSystemIDs`; `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref` | Resolve the selected record to exact OpenStudio sensible-and-latent heat-exchanger names | Comma-separated names | **MANUAL CHECK always:** BuildingSync IDs are not OpenStudio names; verify `HeatRecoveryType = "Air to air heat exchanger"` and use an external object crosswalk |
| `sensible_effectiveness` | `Systems/HeatRecoverySystems/HeatRecoverySystem/HeatRecoveryEfficiency` | Use only for the matched air-to-air record; XSD definition is sensible heat-recovery efficiency | Percent ÷ 100 | Direct metric after identity and operating-condition review |
| `latent_effectiveness` | No direct XSD field; `Systems/HeatRecoverySystems/HeatRecoverySystem/EnergyRecoveryEfficiency` is net total sensible-plus-latent efficiency | Do not map directly; use only an independently documented latent value or derivation | Percent ÷ 100 after derivation | **MANUAL CHECK always:** total energy efficiency is not latent effectiveness |

## Usage

1. Resolve the heat-recovery record to OpenStudio exchanger names.
2. Select sensible or latent effectiveness and enter a fraction from 0 to 1.
3. Run separately when sensible and latent values differ.

The selected value is applied uniformly at 100% and 75% airflow in heating and cooling.
