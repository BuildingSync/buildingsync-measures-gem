# Heating With Terminal Cooling HVAC

Creates a heating source and cooling-only PTACs together in unserved zones. Chaining a heating measure
with `hvac_ptac` fails because each create operation rejects zones the other already serves.

| `heating_source` | Heating | Outdoor air |
| --- | --- | --- |
| `central_gas_furnace` (default) | One shared constant-volume gas-furnace air loop, supply air reset to the coldest zone | Furnace loop; PTACs do not ventilate |
| `hot_water_baseboard` | Hot-water baseboard per zone on a new boiler loop | PTACs |
| `electric_baseboard` | Electric baseboard per zone | PTACs |
| `hot_water_ptac_coil` | Hot-water coil in each PTAC on a new boiler loop | PTACs |

Every PTAC cools with a single-speed DX coil. Except for `hot_water_ptac_coil`, its heating coil is a
zero-capacity, always-off electric placeholder, so the PTAC never heats. Cooling priority goes to the
PTAC and heating priority to the heating source. `boiler_fuel` applies only to the hot-water options.
If a dedicated outdoor-air system already serves the zones, the PTACs do not ventilate.

Only `operation=create` is supported. The zones must be unserved, apart from dedicated outdoor-air
systems.

## BuildingSync mapping

| Measure input | Candidate BuildingSync field(s) | Selection rule | Confidence/notes |
|---|---|---|---|
| Selection | A `CoolingSource` with `DXSystemType = "Packaged terminal air conditioner (PTAC)"` and no heating of its own, plus a separate `HeatingSource` on the same premises | Use only when the heating and terminal cooling records serve the same zone scope | High when the IDREFs agree. Otherwise a resolution profile must confirm the pairing |
| `heating_source` | `HeatingSourceType/Furnace` with a central air `Delivery` → `central_gas_furnace`; `HeatingSourceType/Boiler` with `Delivery/ConvectionType = "Baseboard"` → `hot_water_baseboard`; `ElectricResistance` baseboard → `electric_baseboard`; `Boiler` with the PTAC as its delivery → `hot_water_ptac_coil` | The heating delivery decides the option | Medium. Confirm the hot-water arrangement |
| `boiler_fuel` | `HeatingSource/PrimaryFuel` on the boiler | Map to `NaturalGas`, `Electricity`, `FuelOilNo2`, or `Propane` | High when present |
| `target_zone_names` | `LinkedPremises` IDREFs on the HVAC system or its components | Resolve every IDREF to an exact model-zone name | The consumer resolves BuildingSync IDs to model names |
| `standards_template` | No direct BuildingSync field | Set by workflow or baseline policy | Not audit data |
