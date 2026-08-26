# Modify Existing Heat Recovery

Sets sensible or latent effectiveness on exact, named sensible-and-latent air-to-air heat exchangers.

## BuildingSync mapping

| Argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| `target_heat_exchanger_names` | `HeatRecoverySystem/@ID`, equipment identifiers, shared `LinkedPremises` | Consumer resolves the selected record to exact model names | Comma-separated names | No direct standard model-name field |
| `sensible_effectiveness` | `HeatRecoveryEfficiency` | Use when the record explicitly represents sensible heat recovery | Percent ÷ 100 | Medium-high |
| `latent_effectiveness` | No direct field; `EnergyRecoveryEfficiency` is only a candidate | Use only with a documented derivation or explicit latent audit value | Percent ÷ 100 | Low: total energy effectiveness is not latent effectiveness |

## Usage

1. Resolve the heat-recovery record to OpenStudio exchanger names.
2. Select sensible or latent effectiveness and enter a fraction from 0 to 1.
3. Run separately when sensible and latent values differ.

The selected value is applied uniformly at 100% and 75% airflow in heating and cooling.
