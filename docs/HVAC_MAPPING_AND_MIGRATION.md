# HVAC Measure Mapping and Migration Guide

The monolithic `modify_hvac` measure has been split into independent measures with narrow responsibilities:

- 17 topology measures each support `operation = create` or `operation = replace` for one exact HVAC topology.
- 5 `modify_existing_*` measures change named controls, efficiencies, heat recovery, or plant properties without classifying or rebuilding HVAC.

New workflows should use these independent measures. `modify_hvac` remains in the gem temporarily for backward compatibility and is deprecated.

Start with the [BuildingSync mapping](#buildingsync-hvac-mapping) for schema-driven selection, the [legacy topology index](#exact-topology-index) for migrating existing calls, or the [focused modifiers](#focused-modifiers) for edits to existing equipment. [DOAS layering](#doas-layering-direct-to-zone) and [unit tests](#per-measure-unit-tests) describe runtime behavior and validation.

## BuildingSync HVAC mapping

Scope: BuildingSync **2.7.0**, the **17 split HVAC topology measures**, and their fixed outputs with **openstudio-standards 0.8.2**. The table uses all `PrincipalHVACSystemType` names plus common configurations described by the detailed schema elements. This is a documented mapping contract, not an implemented BuildingSync dispatcher.

### Reading the mapping

- **L100 / family-level data:** use `PrincipalHVACSystemType` to locate the named HVAC family and its available measure/fixed output. The label alone does not establish the detailed configuration in column 2. Generating from that label alone requires an explicit default/approximation policy; none is silently assumed here.
- **L200 / detailed data:** match the actual sources, deliveries, plants, and ventilation records against column 2. A principal label is not required and cannot override conflicting details. L100/L200 describe the intended use here, not schema-enforced restrictions on where these fields may appear.
- **Required predicates:** every semicolon-separated condition is required unless **OR** is written. `exists(path)` includes an empty structural marker; `absent(path)` requires no such element. Exception: an empty `FanBased/FanBasedDistributionType` (no child elements, as exported by L200 audit tools next to `AirSideEconomizer` data) counts as absent. Compare enum values exactly and case-sensitively. A **guard** is optional, but must pass when present; an explicit **Absent** list is mandatory, not optional.
- **Strict mapping gaps are development items:** the listed measure exists and can generate its stated fixed output, but the schema cannot uniquely identify that output or the measure cannot preserve a schema distinction. The gap note identifies a BuildingSync schema and/or gem-measure enhancement needed to close that mismatch. Report **mapping gap — resolution needed**, not an unavailable-measure result. Do not silently treat family evidence as proof of the supported subtype or choose an approximation.
- **Gem-level coverage limits:** **not mappeable in this gem** means the current gem has no measure for that stated configuration; it is not a claim that BuildingSync cannot describe it or OpenStudio cannot model it. Missing input and conflicting input are separate results; report the affected paths/IDs rather than treating them as schema or measure gaps.

#### Path abbreviations and reference context

All paths are relative to `BuildingSync/Facilities/Facility/Systems/HVACSystems/HVACSystem`; there is no intervening `System` element. Abbreviations below stand only for paths, **not reusable predicates**:

- `HC` = `HeatingAndCoolingSystems`; `D` = `HC/Deliveries/Delivery`.
- `HS` = `HC/HeatingSources/HeatingSource`; `CS` = `HC/CoolingSources/CoolingSource`.
- `H` = `HS/HeatingSourceType`; `C` = `CS/CoolingSourceType`; `DX` = `C/DX`.
- `Z` = `D/DeliveryType/ZoneEquipment`; `A` = `D/DeliveryType/CentralAirDistribution`.
- `FC` = `Z/FanBased/FanBasedDistributionType/FanCoil`.
- `HP` = `Plants/HeatingPlants/HeatingPlant`; `CP` = `Plants/CoolingPlants/CoolingPlant`; `CN` = `Plants/CondenserPlants/CondenserPlant`.
- `O` = `OtherHVACSystems/OtherHVACSystem`; `MV` = `O/OtherHVACType/MechanicalVentilation`.

For every delivery-based match, **both** `D/HeatingSourceID/@IDref → HS` and `D/CoolingSourceID/@IDref → CS` are required, including explicit `NoHeating`/`NoCooling` records for ventilation. An arrow means exactly one reference resolves to one selected record of the correct kind. Plant/condenser tests apply only to the referenced records, not any similar plant elsewhere in the XML. Duplicate, broken, or wrong-kind references fail.

`zones(D)` is the nonempty model-zone set resolved from that delivery's own `LinkedPremises`; `zones(O)` uses the other-system record's own links. A delivery or other-system record without its own `LinkedPremises` inherits the parent `HVACSystem/LinkedPremises` (the usual L100/L200 export pattern). Resolve `ThermalZone/LinkedThermalZoneID/@IDref`, or explicitly expand `Space`, `Section`, `Building`, `Site`, or `Facility` links through the model crosswalk. No other inheritance and no all-zones fallback. Source/plant premises, if supplied, must contain their served delivery zones. Select scenario records explicitly; absent `@Status` does not mean `Existing` or `Proposed`.

An XPath implementation must prefix element steps with the namespace `http://buildingsync.net/schemas/bedes-auc/2019`. In particular, the schema fuel is `"Natural gas"`, not the library token `NaturalGas`.

### HVAC configuration mapping

The first 16 rows use the exact named principal enums. Radiant and the following rows cover additional typical configurations. `Other` and `Unknown` are included at the end. **Every row contains its own type predicates; there is no separate predicate table to consult.** For rows with a strict mapping gap, column 2 identifies the family and column 4 explains the remaining work for an exact match; column 3 still lists the available measure and its fixed output.

| HVAC type / configuration | BuildingSync required predicates / exact values | Measure to call / fixed output | Additional notes — guards / strict mapping gaps |
|---|---|---|---|
| **Packaged Terminal Air Conditioner** | **Delivery:** `exists(Z)`.<br>**Heating:** `exists(H/ElectricResistance)`.<br>**Cooling:** `DX/DXSystemType = "Packaged terminal air conditioner (PTAC)"`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`; `absent(CN/AirCooled/EvaporativelyCooledCondenser)`. | [hvac_ptac](../lib/measures/hvac_ptac/measure.rb): one call per delivery; one DX/electric-resistance PTAC per target zone. | **Absent:** `Z/Convection`, `Z/Radiant`, `Z/Other`, `Z/FanBased/FanBasedDistributionType`. `Z/FanBased` itself is optional.<br>**Guards:** `HS/PrimaryFuel` and `CS/PrimaryFuel` = `"Electricity"`; `HS/HeatingMedium = "Air"`; `CS/CoolingMedium` in `{ "Air", "Refrigerant" }`. `D/Quantity` equals its zone count; each source's `Quantity` equals its total distinct served zones, if supplied.<br>Hot-water/gas-heated PTAC variants are **not mappeable in this gem**. |
| **Four Pipe Fan Coil Unit** | **Delivery:** `exists(Z)`; `FC/FanCoilType = "Fan coil 4 pipe"`.<br>**Heating:** `HS/HeatingMedium = "Hot water"`; `H/SourceHeatingPlantID/@IDref → HP`; `HP/Boiler/BoilerType = "Hot water"`; `HP/PrimaryFuel = "Natural gas"`.<br>**Cooling:** `CS/CoolingMedium = "Chilled water"`; `C/CoolingPlantID/@IDref → CP`; `CP/Chiller/ChillerType = "Vapor compression"`; `CP/Chiller/ChillerCompressorDriver = "Electric Motor"`; `CP/Chiller/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `CN/WaterCooled/WaterCooledCondenserType = "Cooling tower"`; `absent(CN/WaterCooled/WaterSideEconomizer)`. | [hvac_four_pipe_fan_coil](../lib/measures/hvac_four_pipe_fan_coil/measure.rb): one four-pipe unit per zone, gas boiler, water-cooled electric chiller.<br>Group deliveries by the exact `(HP ID, CP ID, CN ID)` tuple; one call on their zone union. | **Absent:** `Z/Convection`, `Z/Radiant`, `Z/Other`.<br>**Guards:** `FC/HVACPipeConfiguration = "4 pipe"`; `HS/PrimaryFuel = "Natural gas"`; `CS/PrimaryFuel` and `CP/PrimaryFuel` = `"Electricity"`; `CP/CondenserType = "Water Cooled"`; `HP/Quantity`, `HP/Boiler/Quantity`, `CP/Quantity`, `CP/Chiller/Quantity`, `CN/Quantity` = `1`; `D/Quantity` equals its zone count.<br>**Plant binding:** at most one plant-generating call in the workflow, on a model with no existing plant loops. |
| **Packaged Terminal Heat Pump** | **Delivery:** `exists(Z)`.<br>**Heating:** `H/HeatPump/HeatPumpType = "Packaged Terminal"`; `H/HeatPump/CoolingSourceID/@IDref →` the same `CS` referenced by `D`; `H/HeatPump/HeatPumpBackupSystemFuel = "Electricity"`; `absent(H/HeatPump/LinkedHeatingPlantID)`.<br>**Cooling:** `DX/DXSystemType = "Packaged terminal heat pump (PTHP)"`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`; `absent(CN/AirCooled/EvaporativelyCooledCondenser)`. | [hvac_pthp](../lib/measures/hvac_pthp/measure.rb): one call per delivery; one PTHP per zone, DX heating/cooling and **electric** supplemental heat. | **Absent:** `Z/Convection`, `Z/Radiant`, `Z/Other`, `Z/FanBased/FanBasedDistributionType`. `Z/FanBased` itself is optional.<br>**Guards:** `HS/PrimaryFuel` and `CS/PrimaryFuel` = `"Electricity"`; `HS/HeatingMedium` and `CS/CoolingMedium` in `{ "Air", "Refrigerant" }`. `D/Quantity` equals its zone count; each source's `Quantity` equals its total distinct served zones, if supplied.<br>The wrapper's generic gas argument does not mean gas backup. |
| **Packaged Rooftop Air Conditioner** | **Delivery:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "CAV terminal box no reheat"`; `A/ReheatSource = "None"`; `HC/ZoningSystemType = "Single zone"`.<br>**Heating:** `exists(H/Furnace)`; `HS/PrimaryFuel = "Natural gas"`; `HS/HeatingMedium = "Air"`.<br>**Cooling:** `DX/DXSystemType = "Packaged/unitary direct expansion/RTU"`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`; `absent(CN/AirCooled/EvaporativelyCooledCondenser)`. | [hvac_packaged_rooftop_ac](../lib/measures/hvac_packaged_rooftop_ac/measure.rb): one call per delivery; one single-zone packaged AC loop per zone, gas heating and electric supplemental heat. | **Absent:** `A/ReheatPlantID`, `A/FanBased/FanBasedDistributionType`.<br>**Guards:** `H/Furnace/FurnaceType` in `{ "Warm air", "Other" }` (absent passes; gas fuel, air medium, and the packaged CAV delivery already establish a warm-air furnace section); `CS/PrimaryFuel = "Electricity"`; `CS/CoolingMedium` in `{ "Air", "Refrigerant" }`. `D/Quantity` equals its zone count; each source's `Quantity` equals its total distinct served zones, if supplied.<br>Registers are not automatically substituted for the required CAV terminal value. No separate DOAS on these zones. |
| **Packaged Rooftop Heat Pump** | **Delivery:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "CAV terminal box no reheat"`; `A/ReheatSource = "None"`; `HC/ZoningSystemType = "Single zone"`.<br>**Heating:** `H/HeatPump/HeatPumpType = "Packaged Unitary"`; `H/HeatPump/CoolingSourceID/@IDref →` the same `CS` referenced by `D`; `H/HeatPump/HeatPumpBackupSystemFuel` in `{ "Electricity", "Natural gas" }`; `absent(H/HeatPump/LinkedHeatingPlantID)`.<br>**Cooling:** `DX/DXSystemType = "Packaged/unitary heat pump"`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`; `absent(CN/AirCooled/EvaporativelyCooledCondenser)`. | [hvac_packaged_rooftop_heat_pump](../lib/measures/hvac_packaged_rooftop_heat_pump/measure.rb): one call per delivery; one single-zone packaged HP loop per zone.<br>`supplemental_heating_fuel = Electricity` or `NaturalGas` from `HeatPumpBackupSystemFuel` (`"Natural gas"` → `NaturalGas`). | **Absent:** `A/ReheatPlantID`, `A/FanBased/FanBasedDistributionType`.<br>**Guards:** `CS/PrimaryFuel` = `"Electricity"`; `HS/PrimaryFuel` = `"Electricity"` (the backup fuel is carried by `HeatPumpBackupSystemFuel`); `HS/HeatingMedium` and `CS/CoolingMedium` in `{ "Air", "Refrigerant" }`. `D/Quantity` equals its zone count; each source's `Quantity` equals its total distinct served zones, if supplied.<br>No multizone packaged HP or separate DOAS on these zones. |
| **Packaged Rooftop VAV with Hot Water Reheat** | **Delivery:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "VAV terminal box not fan powered with reheat"`; `HC/ZoningSystemType = "Multi zone"`; `A/ReheatSource = "Heating plant"`.<br>**Heating:** `HS/HeatingMedium = "Hot water"`; `H/SourceHeatingPlantID/@IDref → HP`; `HP/Boiler/BoilerType = "Hot water"`; `HP/PrimaryFuel = "Natural gas"`; `A/ReheatPlantID/@IDref →` that same `HP`.<br>**Cooling:** `DX/DXSystemType = "Packaged/unitary direct expansion/RTU"`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`; `absent(CN/AirCooled/EvaporativelyCooledCondenser)`. | [hvac_packaged_rooftop_vav_hw_reheat](../lib/measures/hvac_packaged_rooftop_vav_hw_reheat/measure.rb): packaged VAV, DX cooling, shared gas-boiler hot-water central heat/reheat, non-fan-powered terminals.<br>One call per `CS ID`, on its delivery-zone union; all members must use the same `HS`, boiler, and condenser IDs. | **Absent:** `A/FanBased/FanBasedDistributionType`.<br>**Guards:** `HS/PrimaryFuel = "Natural gas"`; `CS/PrimaryFuel = "Electricity"`; `CS/CoolingMedium` in `{ "Air", "Refrigerant" }`; `CS/Quantity`, `HP/Quantity` and `HP/Boiler/Quantity` = `1`.<br>**Plant binding:** central heating/reheat cannot select different boilers; at most one plant-generating call on a plant-empty model. No separate DOAS on these zones. |
| **Packaged Rooftop VAV with Electric Reheat** | **Family evidence:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "VAV terminal box fan powered with reheat"`; `HC/ZoningSystemType = "Multi zone"`; `A/ReheatSource = "Local electric resistance"`; `exists(H/ElectricResistance)`; `DX/DXSystemType = "Packaged/unitary direct expansion/RTU"`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`; `absent(CN/AirCooled/EvaporativelyCooledCondenser)`. | [hvac_packaged_rooftop_vav_electric_reheat](../lib/measures/hvac_packaged_rooftop_vav_electric_reheat/measure.rb): DX cooling, electric central heat, **parallel fan-powered** electric-reheat boxes.<br>**Mapping gap — see notes.** | **Strict mapping gap — schema / measure:** the terminal enum combines parallel and series boxes. Add a schema discriminator for that arrangement; extend the measure with series-box support if both are to be generated. The current measure implements only parallel boxes.<br>**Absent:** `A/ReheatPlantID`, `A/FanBased/FanBasedDistributionType`.<br>**Guards:** `HS/PrimaryFuel` and `CS/PrimaryFuel` = `"Electricity"`; `HS/HeatingMedium = "Air"`; `CS/CoolingMedium` in `{ "Air", "Refrigerant" }`. |
| **VAV with Hot Water Reheat** | **Delivery:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "VAV terminal box not fan powered with reheat"`; `HC/ZoningSystemType = "Multi zone"`; `A/ReheatSource = "Heating plant"`.<br>**Heating:** `HS/HeatingMedium = "Hot water"`; `H/SourceHeatingPlantID/@IDref → HP`; `HP/Boiler/BoilerType = "Hot water"`; `HP/PrimaryFuel = "Natural gas"`; `A/ReheatPlantID/@IDref →` that same `HP`.<br>**Cooling:** `CS/CoolingMedium = "Chilled water"`; `C/CoolingPlantID/@IDref → CP`; `CP/Chiller/ChillerType = "Vapor compression"`; `CP/Chiller/ChillerCompressorDriver = "Electric Motor"`; `CP/Chiller/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `CN/WaterCooled/WaterCooledCondenserType = "Cooling tower"`; `absent(CN/WaterCooled/WaterSideEconomizer)`. | [hvac_vav_hw_reheat](../lib/measures/hvac_vav_hw_reheat/measure.rb): chilled-water VAV, shared gas-boiler hot-water central heat/reheat, non-fan-powered terminals.<br>One call per `CS ID`, on its delivery-zone union; all members must use the same `HS` and plant/condenser IDs. | **Absent:** `A/FanBased/FanBasedDistributionType`.<br>**Guards:** `HS/PrimaryFuel = "Natural gas"`; `CS/PrimaryFuel` and `CP/PrimaryFuel` = `"Electricity"`; `CP/CondenserType = "Water Cooled"`; `CS/Quantity`, `HP/Quantity`, `HP/Boiler/Quantity`, `CP/Quantity`, `CP/Chiller/Quantity`, `CN/Quantity` = `1`.<br>**Plant binding:** central heating/reheat cannot select different boilers; at most one plant-generating call on a plant-empty model. No separate DOAS on these zones. |
| **VAV with Electric Reheat** | **Family evidence:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "VAV terminal box fan powered with reheat"`; `HC/ZoningSystemType = "Multi zone"`; `A/ReheatSource = "Local electric resistance"`; `exists(H/ElectricResistance)`.<br>**Cooling:** `CS/CoolingMedium = "Chilled water"`; `C/CoolingPlantID/@IDref → CP`; `CP/Chiller/ChillerType = "Vapor compression"`; `CP/Chiller/ChillerCompressorDriver = "Electric Motor"`; `CP/Chiller/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `CN/WaterCooled/WaterCooledCondenserType = "Cooling tower"`; `absent(CN/WaterCooled/WaterSideEconomizer)`. | [hvac_vav_electric_reheat](../lib/measures/hvac_vav_electric_reheat/measure.rb): chilled-water cooling, electric central heat, **parallel fan-powered** electric-reheat boxes.<br>**Mapping gap — see notes.** | **Strict mapping gap — schema / measure:** the terminal enum combines parallel and series boxes. Add a schema discriminator for that arrangement; extend the measure with series-box support if both are to be generated. The current measure implements only parallel boxes.<br>**Absent:** `A/ReheatPlantID`, `A/FanBased/FanBasedDistributionType`.<br>**Guards:** `HS/PrimaryFuel`, `CS/PrimaryFuel`, `CP/PrimaryFuel` = `"Electricity"`; `HS/HeatingMedium = "Air"`; `CP/CondenserType = "Water Cooled"`; `CP/Quantity`, `CP/Chiller/Quantity`, `CN/Quantity` = `1`. |
| **Warm Air Furnace** | **Delivery:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "CAV terminal box no reheat"`; `A/ReheatSource = "None"`; `HC/ZoningSystemType = "Single zone"`.<br>**Heating:** `exists(H/Furnace)`; `HS/PrimaryFuel = "Natural gas"`; `HS/HeatingMedium = "Air"`.<br>**Cooling:** `exists(C/NoCooling)`. | [hvac_warm_air_furnace](../lib/measures/hvac_warm_air_furnace/measure.rb): one call per delivery; one gas heating-only air loop per zone. | **Absent:** `A/ReheatPlantID`, `A/FanBased/FanBasedDistributionType`.<br>**Guards:** `H/Furnace/FurnaceType` in `{ "Warm air", "Other" }` (absent passes); `D/Quantity` equals its zone count; each source's `Quantity` equals its total distinct served zones, if supplied.<br>Other fuels, electric furnaces, stoves, fireplaces, and individual space heaters are **not mappeable in this gem**. No separate DOAS on these zones. |
| **Ventilation Only** | `MV/VentilationType = "Supply only"`; `O/Integration = "Stand-alone"`; at least one `O/LinkedDeliveryIDs/LinkedDeliveryID/@IDref → D`.<br>**Every linked delivery:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "CAV terminal box no reheat"`; `A/ReheatSource = "None"`; `exists(H/NoHeating)`; `exists(C/NoCooling)`.<br>`zones(O)` equals the union of those deliveries' zones. | [hvac_ventilation_only](../lib/measures/hvac_ventilation_only/measure.rb): one call per `O ID`; unconditioned direct-to-zone outdoor-air loop, supply fan, no heating/cooling coils or heat recovery.<br>Call **after** any compatible zone-conditioning measures. | **Absent:** linked `A/ReheatPlantID`, `A/FanBased/FanBasedDistributionType`; `MV/MakeupAirSourceID`, `MV/VentilationControlMethods`, `MV/VentilationZoneControl`.<br>**Guards:** `MV/DemandControlVentilation` is `false` or `0`; `O/PrimaryFuel = "Electricity"`; `O/Quantity = 1`.<br>Ventilation deliveries must be distinct from conditioning deliveries and cannot be assigned to another ventilation `O`. No overlapping ventilation loops or additional unsupported HRV/ERV/exhaust/humidity-control constituents. |
| **Dedicated Outdoor Air System** | `MV/VentilationType = "Dedicated outdoor air system"`; `O/Integration = "Stand-alone"`; at least one `O/LinkedDeliveryIDs/LinkedDeliveryID/@IDref → D`.<br>**Every linked delivery:** `exists(A)`; `A/AirDeliveryType = "Central fan"`; `A/TerminalUnit = "CAV terminal box no reheat"`; `A/ReheatSource = "None"`; `exists(H/NoHeating)`; `exists(C/NoCooling)`.<br>`zones(O)` equals the union of those deliveries' zones. | [hvac_doas](../lib/measures/hvac_doas/measure.rb): one call per `O ID`; **unconditioned** direct-to-zone outdoor-air loop, supply fan, no heating/cooling coils or heat recovery.<br>Call **after** any compatible zone-conditioning measures. | **Absent:** linked `A/ReheatPlantID`, `A/FanBased/FanBasedDistributionType`; `MV/MakeupAirSourceID`, `MV/VentilationControlMethods`, `MV/VentilationZoneControl`.<br>**Guards:** `MV/DemandControlVentilation` is `false` or `0`; `O/PrimaryFuel = "Electricity"`; `O/Quantity = 1`.<br>Ventilation deliveries must be distinct from conditioning deliveries and cannot be assigned to another ventilation `O`. No overlapping ventilation loops. The DOAS label alone does not establish untreated air. |
| **Water Loop Heat Pump** | **Family evidence:** `exists(Z)`; `exists(H/HeatPump)`; `H/HeatPump/CoolingSourceID/@IDref →` the same `CS` referenced by `D`; `exists(DX)`; a `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN` with `exists(CN/WaterCooled)`. | [hvac_water_loop_heat_pump](../lib/measures/hvac_water_loop_heat_pump/measure.rb): zone water-to-air HPs on a shared loop with gas boiler and evaporative fluid cooler.<br>**Mapping gap — see notes.** | **Strict mapping gap — schema / measure:** the fields do not uniquely encode the generated terminal/shared-loop/fluid-cooler arrangement. Add explicit schema terminal/loop/heat-rejection distinctions and expose measure options for any additional supported arrangements. The principal WLHP label alone does not supply these distinctions.<br>**Guards:** `HS/PrimaryFuel = "Electricity"`; `HS/HeatingMedium` in `{ "Air", "Refrigerant" }`. No invented WLHP `DXSystemType` or `FanCoilType` enum. |
| **Ground Source Heat Pump** | **Family evidence:** `exists(Z)`; `exists(H/HeatPump)`; `H/HeatPump/CoolingSourceID/@IDref →` the same `CS` referenced by `D`; a `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/GroundSource)`.<br>`CN/GroundSource/GroundSourceType` distinguishes `"Open loop ground water"` and `"Closed loop ground source"`. | [hvac_ground_source_heat_pump](../lib/measures/hvac_ground_source_heat_pump/measure.rb): zone HPs on an EMS-controlled temperature-source approximation.<br>**Mapping gap — see notes.** | **Strict mapping gap — measure:** the schema distinguishes physical open-/closed-loop systems, but the measure creates neither well nor borefield geometry. Implement physical loop options in the measure, or expose and explicitly document an approximation mode rather than silently replacing the schema's physical configuration. Missing/unknown ground subtype remains a data issue.<br>**Guards:** `HS/PrimaryFuel = "Electricity"`; `HS/HeatingMedium` in `{ "Air", "Refrigerant" }`. |
| **VRF Terminal Unit** | **Delivery:** `exists(Z)`; `FC/FanCoilType = "VRF terminal units"`.<br>**Heating:** `exists(H/HeatPump)`; `H/HeatPump/CoolingSourceID/@IDref →` the same `CS` referenced by `D`; `absent(H/HeatPump/LinkedHeatingPlantID)`; `absent(H/HeatPump/HeatPumpBackupSystemFuel)`.<br>**Cooling:** `DX/DXSystemType = "Variable refrigerant flow"`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`; `absent(CN/AirCooled/EvaporativelyCooledCondenser)`. | [hvac_vrf](../lib/measures/hvac_vrf/measure.rb): one outdoor unit per `CS ID` group; heating/cooling terminals on the group's zone union.<br>All group members must use the same `HS` and condenser IDs. | **Absent:** `Z/Convection`, `Z/Radiant`, `Z/Other`, `FC/HVACPipeConfiguration`.<br>**Guards:** `CS/Quantity = 1`; `HS/PrimaryFuel` and `CS/PrimaryFuel` = `"Electricity"`; `HS/HeatingMedium` and `CS/CoolingMedium` in `{ "Air", "Refrigerant" }`.<br>`HeatPumpType` is not a selector here. No selectable refrigerant-piping variant; do not substitute `"Multi-split"` for the required terminal enum or merge separate outdoor-unit records. |
| **Chilled Beam** | **Family evidence:** `exists(Z)`; `Z/Convection/ConvectionType = "Chilled beam"`.<br>**Heating:** `HS/HeatingMedium = "Hot water"`; `H/SourceHeatingPlantID/@IDref → HP`; `HP/Boiler/BoilerType = "Hot water"`; `HP/PrimaryFuel = "Natural gas"`.<br>**Cooling:** `CS/CoolingMedium = "Chilled water"`; `C/CoolingPlantID/@IDref → CP`; `CP/Chiller/ChillerType = "Vapor compression"`; `CP/Chiller/ChillerCompressorDriver = "Electric Motor"`; `CP/Chiller/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `CN/WaterCooled/WaterCooledCondenserType = "Cooling tower"`; `absent(CN/WaterCooled/WaterSideEconomizer)`. | [hvac_chilled_beam](../lib/measures/hvac_chilled_beam/measure.rb): active four-pipe heating/cooling beams, gas boiler/water-cooled chiller, and its **own conditioned primary-air loop**.<br>**Mapping gap — see notes.** | **Strict mapping gap — schema / measure:** add native active/passive and beam-pipe-arrangement selectors, and corresponding measure options if variants beyond active four-pipe are needed. `FanBased`, water sources, or a nearby DOAS do not prove the subtype. Do not append a separate DOAS to this builder.<br>**Guards:** `HS/PrimaryFuel = "Natural gas"`; `CS/PrimaryFuel` and `CP/PrimaryFuel` = `"Electricity"`; `CP/CondenserType = "Water Cooled"`; `HP/Quantity`, `HP/Boiler/Quantity`, `CP/Quantity`, `CP/Chiller/Quantity`, `CN/Quantity` = `1`. |
| **Hydronic radiant floor / ceiling** | **Family evidence:** `exists(Z)`; `Z/Radiant/RadiantType = "Radiant floor or ceiling"`.<br>**Heating:** `HS/HeatingMedium = "Hot water"`; `H/SourceHeatingPlantID/@IDref → HP`; `HP/Boiler/BoilerType = "Hot water"`; `HP/PrimaryFuel = "Natural gas"`.<br>**Cooling:** `CS/CoolingMedium = "Chilled water"`; `C/CoolingPlantID/@IDref → CP`; `CP/Chiller/ChillerType = "Vapor compression"`; `CP/Chiller/ChillerCompressorDriver = "Electric Motor"`; `CP/Chiller/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `CN/WaterCooled/WaterCooledCondenserType = "Cooling tower"`; `absent(CN/WaterCooled/WaterSideEconomizer)`. | [hvac_radiant](../lib/measures/hvac_radiant/measure.rb): hydronic heating/cooling **floors**, gas boiler and water-cooled electric chiller.<br>**Mapping gap — see notes.** | **Strict mapping gap — schema / measure:** split the combined floor/ceiling schema value or add a surface-location selector; expose corresponding surface-selection options in the measure to support ceilings. Model floor surfaces do not identify the audited emitter location. No named radiant principal enum.<br>**Guards:** `HS/PrimaryFuel = "Natural gas"`; `CS/PrimaryFuel` and `CP/PrimaryFuel` = `"Electricity"`; `CP/CondenserType = "Water Cooled"`; `HP/Quantity`, `HP/Boiler/Quantity`, `CP/Quantity`, `CP/Chiller/Quantity`, `CN/Quantity` = `1`.<br>The current fixed output does not offer electric, ceiling-only, heating-only, or cooling-only variants. |
| **Split DX air conditioner, with or without furnace** | `DX/DXSystemType = "Split DX air conditioner"`; any linked heating source, including `H/Furnace/FurnaceType = "Warm air"`. | **not mappeable in this gem** — no split-AC topology measure. | Do not substitute packaged rooftop AC. A furnace measure cannot supply the missing split cooling system. |
| **Conventional split / mini-split / multi-split air-source heat pump** | `exists(H/HeatPump)`; `H/HeatPump/CoolingSourceID/@IDref →` the same `CS` referenced by `D`; `DX/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`; (`DX/DXSystemType = "Split heat pump"` **OR** `FC/FanCoilType` in `{ "Mini-split", "Multi-split" }`). | **not mappeable in this gem** — no conventional split-HP/mini-split measure. | `"Multi-split"` is not the distinct `"VRF terminal units"` value. `H/HeatPump/HeatPumpType = "Split"` alone does not establish the cooling/terminal/condenser configuration or override VRF/water-source/ground-source details. |
| **Single-package vertical AC / heat pump** | `DX/DXSystemType` in `{ "Single package vertical air conditioner", "Single package vertical heat pump" }`. | **not mappeable in this gem**. | No vertical-package builder; do not substitute PTAC/PTHP or rooftop equipment. |
| **Field-assembled DX system** | `DX/DXSystemType = "Field-assembled DX system"`. | **not mappeable in this gem**. | No matching topology builder. |
| **Two-pipe / changeover fan coil** | `FC/FanCoilType = "Fan coil 2 pipe"` **OR** (`FC/HVACPipeConfiguration = "2 pipe"` AND (`HS/HeatingMedium = "Hot water"` **OR** `CS/CoolingMedium = "Chilled water"`)). | **not mappeable in this gem**. | The four-pipe builder does not implement changeover. `Fan coil 4 pipe` together with `2 pipe` is conflicting data, not a valid four-pipe match. One-/three-pipe hydronic variants are also unsupported. |
| **Electric or hydronic baseboard / radiator** | `Z/Convection/ConvectionType = "Perimeter baseboard"` **OR** `Z/Radiant/RadiantType = "Radiator"`; linked heating source identifies electric/hydronic/steam supply. | **not mappeable in this gem**. | No baseboard/radiator builder. A radiator is not a radiant slab. |
| **Cooling-only PTAC / VRF; heating- or cooling-only fan coil / radiant** | `exists(H/NoHeating)` AND (`DX/DXSystemType = "Packaged terminal air conditioner (PTAC)"` **OR** `FC/FanCoilType` in `{ "Fan coil 4 pipe", "VRF terminal units" }` **OR** `Z/Radiant/RadiantType = "Radiant floor or ceiling"`); **OR** `exists(C/NoCooling)` AND (`FC/FanCoilType = "Fan coil 4 pipe"` **OR** `Z/Radiant/RadiantType = "Radiant floor or ceiling"`). | **not mappeable in this gem** with the current paired heating/cooling builders. | Explicit `NoHeating`/`NoCooling` is not a switch to omit a coil from those builders. The gas furnace and unconditioned ventilation are separately supported configurations. |
| **Multizone CAV / CAV with terminal reheat** | `A/TerminalUnit = "CAV terminal box with reheat"`; **OR** (`HC/ZoningSystemType = "Multi zone"`; `A/TerminalUnit = "CAV terminal box no reheat"`; at least one of `H/ElectricResistance`, `H/Furnace`, `H/HeatPump`, `H/SourceHeatingPlantID`, `C/DX`, `C/CoolingPlantID`, `C/EvaporativeCooler` exists). | **not mappeable in this gem** — no conditioned multizone CAV builder. | An unconditioned ventilation loop serving several zones is not a conditioned multizone CAV system. |
| **VAV without terminal reheat** | `A/TerminalUnit` in `{ "VAV terminal box fan powered no reheat", "VAV terminal box not fan powered no reheat" }`. | **not mappeable in this gem**. | No VAV-no-reheat builder. Do not remove reheat implicitly from an existing VAV measure. |
| **Non-fan-powered VAV with electric/gas reheat; fan-powered VAV with hydronic/gas reheat** | `A/TerminalUnit = "VAV terminal box not fan powered with reheat"` with `A/ReheatSource` in `{ "Local electric resistance", "Local gas" }`; **OR** `A/TerminalUnit = "VAV terminal box fan powered with reheat"` with `A/ReheatSource` in `{ "Heating plant", "Local gas" }`. | **not mappeable in this gem**. | Available builders pair non-fan-powered boxes with hot-water reheat, or parallel fan-powered boxes with electric reheat; these combinations do not match. |
| **Underfloor air distribution / dual- or three-duct system** | `A/AirDeliveryType = "Low pressure under floor"` **OR** a linked `DuctSystems/DuctSystem/DuctConfiguration` in `{ "Dual", "Three" }`. | **not mappeable in this gem**. | No underfloor/dual-/three-duct builder. Do not confuse underfloor air with radiant floors. |
| **Evaporative cooling** | `C/EvaporativeCooler/EvaporativeCoolingType` in `{ "Direct", "Direct indirect", "Indirect", "Other" }`. | **not mappeable in this gem**. | A zone evaporative cooler is not a WLHP loop fluid cooler or an evaporatively cooled DX condenser. |
| **Steam / district / solar-thermal heating** | `HP/Boiler/BoilerType = "Steam"` **OR** `exists(HP/DistrictHeating)` **OR** `exists(HP/SolarThermal)`, reached through `H/SourceHeatingPlantID/@IDref`. | **not mappeable in this gem** for new-system generation by these wrappers. | Includes district hot water, direct steam, and steam-to-hot-water conversion. No standalone plant builder; plant modifiers do not create or convert these technologies. |
| **Absorption / non-electric-drive chiller or district cooling** | `CP/Chiller/ChillerType = "Absorption"` **OR** `CP/Chiller/ChillerCompressorDriver` in `{ "Steam", "Gas Turbine", "Gas Engine" }` **OR** `exists(CP/DistrictChilledWater)`, reached through `C/CoolingPlantID/@IDref`. | **not mappeable in this gem** for new-system generation. | Includes all absorption heat sources/stages. Library capabilities not exposed by the wrappers are not callable measure options. |
| **Air-cooled chiller** | `C/CoolingPlantID/@IDref → CP`; `exists(CP/Chiller)`; `CP/Chiller/CondenserPlantIDs/CondenserPlantID/@IDref → CN`; `exists(CN/AirCooled)`. | **not mappeable in this gem** as a selectable new-chiller configuration. | The hydronic builders create water-cooled chillers. This does not reject air-cooled DX packaged equipment, which uses a different cooling-source path. |
| **Conditioned DOAS / heated or cooled makeup-air unit** | `MV/VentilationType` in `{ "Dedicated outdoor air system", "Supply only" }`; `O/LinkedDeliveryIDs/LinkedDeliveryID/@IDref → D`; at least one of that delivery's `H/ElectricResistance`, `H/Furnace`, `H/HeatPump`, `H/SourceHeatingPlantID`, `C/DX`, `C/CoolingPlantID`, `C/EvaporativeCooler` exists. | **not mappeable in this gem** — neither ventilation measure creates conditioning coils. | Missing heating/cooling records are missing data, not proof of unconditioned air. A temperature modifier changes sizing fields; it cannot add the missing coils. |
| **Heat-recovery / energy-recovery ventilation** | `MV/VentilationType` in `{ "Heat recovery ventilator", "Energy recovery ventilator" }`. | **not mappeable in this gem** for equipment creation. | [modify_existing_heat_recovery](../lib/measures/modify_existing_heat_recovery/measure.rb) edits an already-existing compatible exchanger; it does not add HRV/ERV to DOAS. |
| **Exhaust-only / spot exhaust** | `MV/VentilationType = "Exhaust only"` **OR** `exists(O/OtherHVACType/SpotExhaust)`. | **not mappeable in this gem**. | Includes bathroom, kitchen-hood, and laboratory-hood exhaust. Supply ventilation is not an exhaust-only substitute. |
| **Humidification / dehumidification / air cleaning** | `exists(O/OtherHVACType/Humidifier)` **OR** `exists(O/OtherHVACType/Dehumidifier)` **OR** `exists(O/OtherHVACType/AirCleaner)`. | **not mappeable in this gem**. | No corresponding equipment-creation measure. These additional constituents cannot be silently dropped from a complete configuration. |
| **Natural ventilation** | `exists(O/OtherHVACType/NaturalVentilation)`. | **not mappeable in this gem**. | Neither mechanical supply ventilation nor infiltration is an equivalent implementation. |
| **Explicitly no HVAC** | `exists(H/NoHeating)`; `exists(C/NoCooling)`; `absent(D/DeliveryType)`; `MV/VentilationType = "None"`; `O/LinkedDeliveryIDs/LinkedDeliveryID/@IDref → D`; `zones(O) = zones(D)`; no other selected delivery/other-system record serves these zones. | **No measure call.** | Absent HVAC data is not an explicit no-HVAC declaration. `VentilationType = "None"` alone does not disable the outdoor air generated by a conditioning builder. |
| **Integrated outdoor-air record** | `exists(MV)`; `O/Integration` in `{ "Integrated with central air distribution", "Integrated with local air distribution" }`; any `MV/VentilationType` except `"Dedicated outdoor air system"`; linked deliveries, if any, resolve to `D`. | **No ventilation measure call.** The linked deliveries are matched as ordinary conditioning deliveries; the conditioning builder supplies their outdoor air. | Does not consume its deliveries, so several records on one delivery are not a conflict and an integrated record on a conditioned delivery is not a conditioned DOAS. `DemandControlVentilation`/`VentilationRate` are unmapped properties reserved for a future modifier. |
| **Untyped or `None` ventilation on conditioned deliveries** | `exists(MV)`; (`MV/VentilationType = "None"` **OR** `absent(MV/VentilationType)`); at least one linked delivery is not explicitly unconditioned (not both `H/NoHeating` and `C/NoCooling`). | **No ventilation measure call.** Linked deliveries are matched as conditioning deliveries. | Common in ASHRAE L1/L2 exports. Report `no_hvac` for `None` and missing input for untyped records, without blocking the conditioning match; neither value disables builder outdoor air. Only when every linked delivery is explicitly unconditioned does the record consume them (see **Explicitly no HVAC**). |
| **Other** | `PrincipalHVACSystemType = "Other"` supplies no detailed type predicates. Evaluate any actual source/delivery/plant records independently. | **not mappeable in this gem from the principal value alone**. | This label lacks configuration data; it is not evidence that a measure is unavailable. Detailed data may still match a listed configuration, including one without a dedicated principal enum. `Other` markers in required detailed fields do not supply missing facts. |
| **Unknown** | `PrincipalHVACSystemType = "Unknown"` supplies no detailed type predicates. Evaluate any actual source/delivery/plant records independently. | **not mappeable in this gem from the principal value alone**. | This label lacks configuration data; it is not evidence that a measure is unavailable. Unknown or missing detailed fields are not permission to select measure defaults. Deprecated `PrimaryHVACSystemType` is likewise family information, not a detailed-match override. |

### Applying one or multiple mappings

- **Zone equipment is structural:** `Z` means the actual `D/DeliveryType/ZoneEquipment` element, not a `FanCoilType` enum. Its existence is required in the relevant rows, but never sufficient on its own. Likewise, an empty `FanBased` element is allowed where only `FanBasedDistributionType` is excluded. Reject incompatible extra delivery mechanisms rather than ignoring them.
- **Separate conditioning and ventilation:** individually matching PTAC, PTHP, four-pipe fan-coil, or VRF configurations can coexist with an individually matching unconditioned DOAS/supply-only configuration. Use separate delivery IDs; overlapping premises alone do not establish their relationships. Run all conditioning measures first, then `hvac_doas`/`hvac_ventilation_only`, retaining each call's own zone set. For example, PTAC on `{A, B}` plus DOAS on `{B, C}` produces PTACs on A/B and ventilation on B/C; only B's PTAC outdoor air is zeroed. Rooftop/VAV/furnace air loops cannot share zones with a separate DOAS. Pairing with ventilation does not resolve a schema/measure mapping gap.
- **No silent stacking or partial generation:** two conditioning deliveries cannot overlap zones, even if they would later be grouped; two ventilation groups cannot overlap either. Disjoint mapped configurations can be generated separately, subject to plant/identity limits. Every selected constituent must be accounted for. If any constituent has missing/conflicting data, a mapping gap, or no corresponding gem measure, hold the complete executable plan and report each issue in its own category; a smaller scope must be explicitly requested. Do not collapse mapping gaps into unavailable-measure results or silently omit HRV/ERV/exhaust/humidity-control/natural-ventilation constituents.
- **Preserve identity and grouping:** quantities are not inherently zone counts. The `CS/Quantity = 1` guard on grouped VAV/VRF rows is a one-air-system/outdoor-unit contract: an omitted quantity (typical in L200 exports) is read as one record per system, while any other value fails. Do not reuse one `CS ID` as both independent per-zone rooftop equipment and a grouped VAV/VRF system, or let separate VRF groups silently share one condenser record. Current wrappers have no arbitrary plant-ID binding; the single-plant-generating-call restriction stated in the hydronic rows is conservative mapping policy, not a claim that OpenStudio cannot model multiple plants. Supporting more general graphs requires explicit plant-ID binding and reuse options in the gem/workflow.
- **Linked ducts:** resolve each selected `DuctSystems/DuctSystem/HeatingDeliveryID/@IDref` and/or `CoolingDeliveryID/@IDref` to its delivery; at least one link is required for a requested duct record. `DuctConfiguration`, if present, must be `"Single"` for central-air delivery or `"Ductless"` for zone equipment in this profile. `DuctType = "No ducting"` conflicts with central-air delivery. Duct material, leakage, and explicit duct-loss modeling are separate unmapped properties.
- **Invocation:** pass explicit `target_zone_names = zones(group)` and use `operation = create` on HVAC-empty target zones, except the planned zone-equipment → ventilation layering. Existing HVAC requires a separately planned `replace` operation with complete shared-system scope; `@Status = "Proposed"` alone does not select replacement. Sort conditioning calls by `(measure name, group ID)` and then ventilation calls by `O ID` for stable ordering. Choose `standards_template` explicitly from `90.1-2013`, `90.1-2016`, `90.1-2019`, or record the measure default `90.1-2019`.
- **Topology is not property transfer:** capacities, efficiencies, control sequences, temperatures, schedules, and outdoor-air rates are not automatically transferred by a topology match. Explicit `ReheatControlMethod` values do not select a new topology and are unsupported selectable sequences; on a no-reheat delivery, report them as unmapped properties. Apply a modifier only after separately resolving its exact source value/units, supported target objects, and arguments; see [focused modifiers](#focused-modifiers).

Do not fall back to the deprecated monolithic measure for an unresolved configuration. Report the matched HVAC type, contributing IDs, exact zone set, ordered measure calls/arguments, and any missing/conflicting input, schema/measure development gaps, or gem-level coverage limits separately. The requirements above govern deterministic selection; they do not prevent manually configuring an available measure for its documented fixed output.

## Choosing an operation

1. Resolve BuildingSync IDs and linked premises to exact OpenStudio object and thermal-zone names before invoking a measure.
2. Choose one exact topology using the [BuildingSync mapping](#buildingsync-hvac-mapping) or [legacy topology index](#exact-topology-index).
3. Set `operation = create` only when every target zone is unserved. A blank `target_zone_names` selects all thermal zones. Exception: DOAS/ventilation-only loops are an outdoor-air layer. `hvac_doas` and `hvac_ventilation_only` can be created on zones that have zone equipment but no air loop; run them after all other HVAC upgrades. Zone-equipment topologies (PTAC, PTHP, fan coil, WLHP, GSHP, radiant, VRF) can be created on DOAS-served zones. When a zone-equipment topology replaces equipment, it keeps the DOAS loop. When DOAS/ventilation-only replaces, it replaces only the air loops and keeps the zone equipment. Air-loop topologies still conflict with DOAS-served zones. See [DOAS layering](#doas-layering-direct-to-zone).
4. Set `operation = replace` when existing HVAC dedicated to named zones must be removed. Replacement requires an explicit, complete `target_zone_names` list.
5. Run focused `modify_existing_*` measures afterward for audited temperatures, efficiencies, capacities, economizers, or heat recovery.

Selection of the topology, interpretation of legacy aliases, and BuildingSync ID-to-model-name resolution belong to the consuming workflow. The measures do not dispatch from a BuildingSync enum or infer object names.

## Exact topology index

| Legacy `hvac_system_type` | Topology measure |
|---|---|
| `packaged_terminal_air_conditioner` | [`hvac_ptac`](../lib/measures/hvac_ptac/README.md) |
| `packaged_terminal_heat_pump` | [`hvac_pthp`](../lib/measures/hvac_pthp/README.md) |
| `four_pipe_fan_coil_unit` | [`hvac_four_pipe_fan_coil`](../lib/measures/hvac_four_pipe_fan_coil/README.md) |
| `packaged_rooftop_air_conditioner` | [`hvac_packaged_rooftop_ac`](../lib/measures/hvac_packaged_rooftop_ac/README.md) |
| `packaged_rooftop_heat_pump` | [`hvac_packaged_rooftop_heat_pump`](../lib/measures/hvac_packaged_rooftop_heat_pump/README.md) |
| `packaged_rooftop_vav_hot_water_reheat` | [`hvac_packaged_rooftop_vav_hw_reheat`](../lib/measures/hvac_packaged_rooftop_vav_hw_reheat/README.md) |
| `packaged_rooftop_vav_electric_reheat` | [`hvac_packaged_rooftop_vav_electric_reheat`](../lib/measures/hvac_packaged_rooftop_vav_electric_reheat/README.md) |
| `vav_with_hot_water_reheat` | [`hvac_vav_hw_reheat`](../lib/measures/hvac_vav_hw_reheat/README.md) |
| `vav_with_electric_reheat` | [`hvac_vav_electric_reheat`](../lib/measures/hvac_vav_electric_reheat/README.md) |
| `warm_air_furnace` | [`hvac_warm_air_furnace`](../lib/measures/hvac_warm_air_furnace/README.md) |
| `ventilation_only` | [`hvac_ventilation_only`](../lib/measures/hvac_ventilation_only/README.md) |
| `dedicated_outdoor_air_system` | [`hvac_doas`](../lib/measures/hvac_doas/README.md) |
| `water_loop_heat_pump` | [`hvac_water_loop_heat_pump`](../lib/measures/hvac_water_loop_heat_pump/README.md) |
| `ground_source_heat_pump` | [`hvac_ground_source_heat_pump`](../lib/measures/hvac_ground_source_heat_pump/README.md) |
| `vrf_terminal_unit` | [`hvac_vrf`](../lib/measures/hvac_vrf/README.md) |
| `chilled_beam` | [`hvac_chilled_beam`](../lib/measures/hvac_chilled_beam/README.md) |
| `radiant_system` | [`hvac_radiant`](../lib/measures/hvac_radiant/README.md) |

Each linked README contains the measure-specific BuildingSync candidate mapping, selection rules, conversions, confidence, and limitations.

## Legacy aliases and metadata-only choices

| Legacy choice | Migration |
|---|---|
| `vav_with_boiler_and_central_chiller` | Resolve upstream to `vav_with_hot_water_reheat`, then set the measure operation. |
| `fan_coil_with_central_plant` | Resolve upstream to `four_pipe_fan_coil_unit`, then set the measure operation. |
| `other` | Do not invoke a topology measure until the consumer resolves an exact supported topology. |
| `unknown` | Leave HVAC unchanged or resolve the topology upstream. |
| `existing_unknown_mixed_system` | Leave HVAC unchanged or resolve each constituent system upstream. |

The aliases are intentionally not implemented as dispatching measures.

## Focused modifiers

| Measure | Scope and invocation model |
|---|---|
| [`modify_existing_air_loop_controls`](../lib/measures/modify_existing_air_loop_controls/README.md) | Exact air-loop names; optionally changes cooling/heating design supply-air temperatures and/or economizer settings. |
| [`modify_existing_hvac_equipment_efficiencies`](../lib/measures/modify_existing_hvac_equipment_efficiencies/README.md) | Exact component or equipment names; applies one selected efficiency metric and value per invocation. |
| [`modify_existing_plant_equipment`](../lib/measures/modify_existing_plant_equipment/README.md) | Exact boiler or chiller names; applies one selected capacity or efficiency property and value per invocation. |
| [`modify_existing_heat_recovery`](../lib/measures/modify_existing_heat_recovery/README.md) | Exact sensible-and-latent heat-exchanger names; applies sensible or latent effectiveness per invocation. |
| [`modify_existing_plant_loop_temperatures`](../lib/measures/modify_existing_plant_loop_temperatures/README.md) | Exact plant-loop names; sets the sizing design loop exit temperature. |

### Legacy argument migration

| Legacy `modify_hvac` argument | Independent measure migration |
|---|---|
| `hvac_system_type` | Select one exact neutral measure from the topology index. |
| `target_zone_names` | Pass to the selected topology measure after resolving BuildingSync premises. |
| `target_air_loop_name` | Use plural `target_air_loop_names` in `modify_existing_air_loop_controls`. Blank no longer means all; provide exact names. |
| `synthesize_if_missing` | Choose explicitly: `operation = create`, `operation = replace`, or a modifier for existing objects. |
| `central_cooling_supply_air_temperature_c`, `central_heating_supply_air_temperature_c` | `modify_existing_air_loop_controls` with `set_supply_air_temperatures = true`. |
| `doas_supply_air_temperature_c` | `modify_existing_air_loop_controls` on the resolved DOAS or primary-air loop. |
| `economizer_control_type`, `economizer_high_limit_dry_bulb_temperature_c`, `economizer_high_limit_enthalpy_j_kg` | `modify_existing_air_loop_controls` with `set_economizer = true`. |
| `dx_cooling_cop` | `modify_existing_hvac_equipment_efficiencies` metric `dx_cooling_cop`. |
| `gas_furnace_thermal_efficiency` | `modify_existing_hvac_equipment_efficiencies` metric `gas_burner_efficiency`. |
| `heat_pump_cooling_cop` | Select `dx_cooling_cop`, `water_to_air_cooling_cop`, or `vrf_cooling_cop` according to the exact named object type. |
| `heat_pump_heating_cop` | Select `dx_heating_cop`, `water_to_air_heating_cop`, or `vrf_heating_cop` according to the exact named object type. |
| `backup_resistance_efficiency` | `modify_existing_hvac_equipment_efficiencies` metric `electric_heating_efficiency`. |
| `boiler_capacity_kw`, `design_heating_capacity_kw` | `modify_existing_plant_equipment` property `boiler_capacity_kw`; the generic design value requires an explicitly resolved boiler target. |
| `boiler_nominal_thermal_efficiency` | `modify_existing_plant_equipment` property `boiler_thermal_efficiency`. |
| `chiller_capacity_tons`, `design_cooling_capacity_tons` | `modify_existing_plant_equipment` property `chiller_capacity_tons`; the generic design value requires an explicitly resolved chiller target. |
| `chiller_reference_cop` | `modify_existing_plant_equipment` property `chiller_reference_cop`. |
| `erv_sensible_effectiveness` | `modify_existing_heat_recovery` metric `sensible_effectiveness`. |
| `erv_latent_effectiveness` | `modify_existing_heat_recovery` metric `latent_effectiveness`. |
| `radiant_chilled_water_supply_temperature_c`, `radiant_hot_water_supply_temperature_c` | `modify_existing_plant_loop_temperatures`; invoke separately for exact cooling and heating loop names. |
| `chilled_beam_primary_air_fraction` | No model-changing replacement; retain as audit/workflow metadata if needed. |
| `year_installed`, `condition_assessment`, `control_type_audit`, `zone_control_strategy` | No model-changing replacement; retain in the BuildingSync/audit data layer. |
| `preserve_existing_sizing` | No direct argument. Capacity remains unchanged unless a capacity property is explicitly applied with `modify_existing_plant_equipment`; newly created systems use standards sizing defaults. |

## Safety and lifecycle rules

- `create` fails when a target zone already has zone HVAC or air-loop service.
- `replace` resolves all target names and rejects partial removal of shared air loops before deletion. VRF also rejects partial removal of a shared outdoor unit.
- `replace` keeps every pre-existing plant loop that still serves a load after the replacement, for example a loop shared with zones outside the target scope or a loop that openstudio-standards reuses for the new system. A pre-existing loop left without any demand-side load is removed together with its supply equipment (boilers, chillers, cooling towers, pumps). Removing a chiller can leave its condenser loop without loads, in which case that loop is removed as well. Loops that already had no loads before the replacement are not touched.
- Messages that openstudio-standards logs while building a system are forwarded to the measure result: warnings as measure warnings, errors as measure errors that fail the step. openstudio-standards returns the model even when a step failed, so its log is the only reliable error signal; the measures also verify that every target zone received equipment.
- OpenStudio model edits are not transactional. A failure during synthesis can leave an in-memory model partially changed; run replacements against a disposable copy or workflow checkpoint.
- Modifiers use exact OpenStudio object names. They do not accept BuildingSync IDs, wildcards, or inferred relationships.
- Topology measures use `90.1-2013`, `90.1-2016`, or `90.1-2019`; the default is `90.1-2019`.

## Topology-specific limitations

- **PTAC:** DX cooling with electric-resistance heating. No hot-water plant is created.
- **Packaged rooftop AC:** DX cooling with a gas furnace heating coil and electric supplemental heat. No hot-water plant is created.
- **Ventilation-only:** constructed directly because openstudio-standards 0.8.2 does not recognize a `Ventilation Only` key. It does not provide separate zone sensible conditioning.
- **DOAS:** constructed directly. It has outdoor-air delivery and a fan but no outdoor-air heating/cooling coils or separate zone sensible-conditioning system.
- **Chilled beam:** openstudio-standards 0.8.2 has no chilled-beam key. The measure creates supporting plants through temporary fan-coil synthesis, removes those fan coils, installs four-pipe beams, and builds the primary-air loop directly. The primary-air loop has hot- and chilled-water coils held at a constant 14 °C supply-air setpoint, but no heat recovery or humidity controls. Beam sizing depends on zone design outdoor-air rates; low primary-air flow can produce undersized beams.
- **Radiant:** requires modeled zone surfaces. Standards changes constructions and assigns internal-source radiant surfaces; BuildingSync commonly lacks enough information to map individual surfaces.
- **Plant-based systems:** openstudio-standards reuses a pre-existing loop only when it carries the standards default name (`Hot Water Loop`, `Chilled Water Loop`, `Heat Pump Loop`, `Ground HX Loop`, `Ambient Loop`); otherwise new plants are created next to the existing ones. Apply audited plant properties afterward with focused modifiers.

## DOAS layering (direct to zone)

`hvac_doas` and `hvac_ventilation_only` build a ventilation loop sized on `VentilationRequirement`, with one `AirTerminalSingleDuctConstantVolumeNoReheat` per zone. The other measures recognize a loop with this setup as a DOAS loop. The loop delivers outdoor air **directly to each zone**, in parallel with the zone equipment. It is not ducted to the zone units' inlets.

```text
Outdoor air -> DOAS loop (OA system + fan) -> CV NoReheat terminal -> Zone
Zone air    -> PTAC / PTHP / fan coil / WAHP / VRF terminal (OA = 0) -> Zone
```

- **Single outdoor-air source:** the DOAS loop is the only source of outdoor air for each zone it serves. When `hvac_doas` or `hvac_ventilation_only` runs, it sets the outdoor-air flows of every existing zone unit in the target zones to 0 and logs an info message. The fields set to 0 are:
  - PTAC, PTHP, water-to-air heat pump and VRF terminal: the outdoor-air flow during cooling, during heating, and when no heating or cooling is needed.
  - Four-pipe fan coil: the maximum outdoor-air flow.
  - Radiant systems and baseboards have no outdoor air, so they are unchanged.
- **Required order: run DOAS last.** Apply `hvac_doas` / `hvac_ventilation_only` after every other HVAC upgrade in the workflow. The zone-equipment measures do not change outdoor air. If one runs after the DOAS measure, its new units keep their standards-based outdoor air, and ventilation is counted twice.
- **Zone-equipment measures on DOAS-served zones:** they are still allowed, and `replace` removes zone units but keeps the DOAS loop and its terminals. Re-run the DOAS measure afterward with `operation = replace` on those zones; it rebuilds the DOAS loop and sets the new units' outdoor air to 0.
- **Load order:** the DOAS terminal is set first in each zone's cooling and heating order. The zone units handle the remaining sensible load.
- **DOAS `replace`:** removes only the air loops serving the target zones, including their outdoor-air systems. Zone equipment is kept.
- **Not supported:** air-loop topologies (packaged rooftop, VAV, furnace, chilled beam) are rejected on DOAS-served zones, because they bring their own outdoor-air system.
- **Untreated supply air:** the DOAS loop has no outdoor-air heating or cooling coils, so the zone units absorb the outdoor-air load.

## Per-measure unit tests

All 17 independent HVAC topology measures and five `modify_existing_*` HVAC modifiers contain a local Minitest entry point and a checked-in OSM fixture. The deprecated `modify_hvac` suite is not part of this test group.

Examples:

- [DOAS test entry point](../lib/measures/hvac_doas/tests/hvac_doas_test.rb) and [fixture](../lib/measures/hvac_doas/tests/test_model.osm).
- [Plant-equipment modifier tests](../lib/measures/modify_existing_plant_equipment/tests/modify_existing_plant_equipment_test.rb) and [fixture](../lib/measures/modify_existing_plant_equipment/tests/test_model.osm).
- [Radiant tests](../lib/measures/hvac_radiant/tests/hvac_radiant_test.rb), including a zone-without-surfaces error.
- [Heat-recovery tests](../lib/measures/modify_existing_heat_recovery/tests/modify_existing_heat_recovery_test.rb), including zero effectiveness and re-enabling recovery.

### Running tests

Use the repository's bundled Ruby dependencies with OpenStudio's Ruby bindings available. The tested SDK/dependency baseline is OpenStudio 3.10.0, Ruby 3.2, and openstudio-standards 0.8.2. No weather download or EnergyPlus simulation is required.

From the repository root:

```bash
# All 22 independent measures
bundle exec rake test_hvac

# One local suite
bundle exec ruby lib/measures/hvac_doas/tests/hvac_doas_test.rb --verbose

# One scenario
bundle exec ruby lib/measures/hvac_doas/tests/hvac_doas_test.rb --name test_default_create_and_forward_translation

# Select a suite through Rake
bundle exec rake test_hvac TEST=lib/measures/modify_existing_plant_equipment/tests/modify_existing_plant_equipment_test.rb

# Existing cross-measure integration suite remains separate
bundle exec rake spec
```

If the Windows Bundler launcher causes problems, invoke Ruby directly with Bundler preloaded:

```powershell
& 'C:\Ruby32-x64\bin\ruby.exe' -rbundler/setup -S rake test_hvac
& 'C:\Ruby32-x64\bin\ruby.exe' -rbundler/setup lib/measures/hvac_doas/tests/hvac_doas_test.rb --verbose
```

Adjust the interpreter location for the local installation. The direct suites require the repository or installed gem layout, including the shared test support directory; copying only a measure directory does not copy the shared harness. Production measures do not depend on this harness.

### What is checked

Each topology suite includes these common scenarios:

| Scenario | Checks |
| --- | --- |
| Argument contract | Names, operation choices/default, and all three supported standards templates |
| Default creation | All fixture zones served by the correct equipment; EnergyPlus forward translation has no errors and retains zone equipment connections |
| Explicit multi-zone scope, 2013 template | Whitespace and duplicate names handled; unselected zone equipment preserved |
| Single-zone scope, 2016 template | Correct system created only in the selected zone |
| Replacement, default 2019 template | Selected existing air loop removed; zone equipment replaced or retained as appropriate; unrelated zone equipment and plant loop preserved |
| Served-zone creation | Explicit failure without partial model changes |
| Partial shared-loop replacement | Explicit failure without removing shared equipment |
| Mixed valid/missing zone names | Failure before any changes |
| Blank replacement scope | Failure without destroying existing equipment |
| No thermal zones | Explicit failure |

Topology-specific assertions inspect terminal/unit types, zone connections, heating/cooling coil types and plant connections. Additional tests cover DOAS/ventilation priority, a connected supply fan, elimination of duplicate zone-unit outdoor air, radiant surface requirements, and rejection of partial VRF outdoor-unit replacement.

Modifier suites check:

- Every supported plant capacity/efficiency property, including kW-to-W and ton-to-W conversion.
- All eight equipment efficiency metrics, plus both speeds of two-speed DX cooling coils.
- Sensible/latent effectiveness in heating and cooling at both airflow levels, inclusive 0 and 1 boundaries, repeated disabling/restoration, and unsupported effectiveness curves.
- Supply-air temperatures, all six economizer types, combined changes, no-op/NA behavior, missing electronic-enthalpy curves, and warnings for loops without outdoor air.
- Heating, chilled-water, and radiant loop design temperatures.
- Exact-name scope, multiple/duplicate names, preservation of unselected objects, missing names, invalid numeric bounds where defined, and incompatible object/property combinations.

Every intentional rejection verifies the complete serialized model is unchanged, rather than only checking an object count. Supported mixed-object updates verify the incompatible object is preserved and a warning is recorded.

These are model-editing unit tests with forward-translation smoke checks, **not** annual energy, sizing, comfort, or equipment-performance validation. The existing RSpec suite covers additional cross-measure interactions and orphaned-plant cleanup.

### Inspecting artifacts

Every call to the measure writes into its own local test directory:

```text
tests/output/<test_method>/<invocation_number>/
  in.osm       # model immediately before the measure runs
  out.osm      # model after the run, including failed runs
  result.json  # supplied argument overrides, return value, status, logs, exception if any
```

The harness reloads the output with `VersionTranslator` before assertions. The fixture is never overwritten by a test. Invocation numbers distinguish repeated runs within a scenario; rerunning the same test overwrites the corresponding artifacts. The output directories are ignored by Git. Avoid running two copies of the same suite concurrently, since their artifact paths overlap.

An intentional error case has `status: Fail` in its runner report even when the **test passes**. The report records measure execution, not the later Minitest assertion verdict; the test console/exit code is authoritative. Unexpected Ruby exceptions also leave diagnostic artifacts and are re-raised as test errors.

CI runs the local suites alongside RSpec and archives local test artifacts if validation fails.

### Fixtures and maintenance

Topology inputs have three named, unserved zones (`Zone One`, `Zone Two`, `Zone Three`) with floor/wall/roof geometry, constructions, dual-setpoint thermostats, lights, outdoor-air specifications, design days, and a fixed calendar year. Tests add existing baseboards or air loops in memory to stage replacement/conflict cases.

Modifier inputs include two separately named air systems with heat recovery and heating/cooling plants, allowing targeted changes to be checked against untouched equipment. The efficiency fixture also contains deliberately isolated component pairs for every supported efficiency setter. These small inputs are unit-test fixtures, not complete simulation-ready reference buildings.

Tests fail immediately if their fixture is missing or unreadable; there is no fallback to an empty model. Normal test runs **do not** regenerate fixtures.

To deliberately regenerate all 22 fixtures after changing their design:

```bash
bundle exec rake hvac_test_fixtures
bundle exec rake test_hvac
```

This overwrites the input models using the installed SDK; review and commit those changes together with the fixture-generator changes. OpenStudio creates fresh UUIDs, so regeneration can produce a large diff even without geometry changes.

Shared test-only code lives in:

- [Runner, artifact, and assertion helpers](../lib/openstudio/buildingsync_measures/test_support/hvac_measure_test.rb).
- [Reusable topology/ventilation scenarios](../lib/openstudio/buildingsync_measures/test_support/hvac_topology_tests.rb).
- [Reusable modifier validation scenarios](../lib/openstudio/buildingsync_measures/test_support/hvac_modifier_tests.rb).
- [Explicit fixture generator](../lib/openstudio/buildingsync_measures/test_support/generate_hvac_fixtures.rb).

To extend coverage, add a `test_*` method to the relevant local suite, load the fixture through the inherited setup, call `run_measure`, and assert the resulting model properties. Keep shared behavior in the harness, and topology/property-specific expectations in the local test file.

## Deprecation status

`modify_hvac` is retained temporarily so existing workflows can migrate. It should not be selected by new workflows. Removal of the legacy directory, its direct test, and its package inventory entry is a separate breaking-release step.
