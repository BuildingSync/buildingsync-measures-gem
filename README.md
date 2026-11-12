# Buildingsync Measures Gem

This repository contains measures used in the BuildingSync to OpenStudio Simulator ([BOSS](https://github.com/BuildingSync/BOSS)) workflow.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'buildingsync-measures'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'buildingsync-measures'

## Usage

Measures are packaged as OpenStudio extension measures under `lib/measures` and can be registered from the repository root:

```bash
openstudio --verbose measure -r ./lib/measures
```

## Measure inventory

General model measures:

- `disable_sizing_runs` - disables sizing-period simulation and keeps weather-file run periods enabled.
- `modify_envelope_insulation` - adjusts exterior wall, roof, and floor construction insulation to target R-values or U-values.
- `modify_schedules` - creates or replaces OpenStudio schedules from BuildingSync-aligned schedule payloads.
- `set_infiltration_by_ach` - updates existing infiltration objects to a natural ACH value, with optional ACH50 conversion.

HVAC configuration is split into 22 independent measures:

- 17 neutral topology measures each support `operation = create` and `operation = replace`.
- `modify_existing_air_loop_controls`
- `modify_existing_hvac_equipment_efficiencies`
- `modify_existing_plant_equipment`
- `modify_existing_heat_recovery`
- `modify_existing_plant_loop_temperatures`

See the [HVAC mapping and migration guide](docs/HVAC_MIGRATION.md) for the full BuildingSync predicates, legacy `modify_hvac` mappings, workflow responsibilities, and known limitations. The monolithic `modify_hvac` measure is retained temporarily for backward compatibility but is deprecated for new workflows.

## BuildingSync HVAC mapping overview

For **L100 / family-level data**, `PrincipalHVACSystemType` locates a system family. For **L200 / detailed data**, use the linked sources, deliveries, plants, and ventilation records to identify the actual configuration. These are intended audit uses, not schema-enforced field restrictions; a principal label alone does not establish a detailed match.

This is a **short overview**, not the complete selection contract. Field names and conditions are abbreviated below. Use the [full four-column mapping](docs/HVAC_MIGRATION.md#buildingsync-hvac-mapping) for exact paths/values, required ID references, guards, zone grouping, and call arguments. The baseline is BuildingSync 2.7.0 and openstudio-standards 0.8.2; the measures do not parse BuildingSync themselves.

**Mapping gaps** identify schema or measure enhancements needed for an exact match; the listed measures still exist and produce the stated output. **Not mappeable in this gem** identifies configurations with no current matching gem measure, not a limitation of BuildingSync or OpenStudio. Missing/unknown data is a separate issue.

| HVAC type / configuration | BuildingSync configuration — summary only | Measure / fixed output | Notes / development gaps |
|---|---|---|---|
| Packaged Terminal Air Conditioner | `ZoneEquipment`; PTAC DX source, electric resistance, air-cooled condenser | [hvac_ptac](lib/measures/hvac_ptac/README.md): DX cooling + electric heat, one unit/zone | No gas/hot-water PTAC variant. |
| Four Pipe Fan Coil Unit | `FanCoilType = "Fan coil 4 pipe"`; hot-water boiler + chilled-water plant | [hvac_four_pipe_fan_coil](lib/measures/hvac_four_pipe_fan_coil/README.md): four-pipe units, gas boiler, water-cooled electric chiller | Exact plant IDs/grouping matter; no two-pipe changeover. |
| Packaged Terminal Heat Pump | `ZoneEquipment`; packaged-terminal HP + PTHP DX source, electric backup, air-cooled condenser | [hvac_pthp](lib/measures/hvac_pthp/README.md): DX heating/cooling + electric backup, one unit/zone | Backup is electric, not gas. |
| Packaged Rooftop Air Conditioner | Single-zone central air, CAV no-reheat terminal; packaged DX + gas furnace | [hvac_packaged_rooftop_ac](lib/measures/hvac_packaged_rooftop_ac/README.md): one packaged AC loop/zone | Gas heat + electric supplemental heat. |
| Packaged Rooftop Heat Pump | Single-zone central air, CAV no-reheat terminal; packaged-unitary HP + electric backup | [hvac_packaged_rooftop_heat_pump](lib/measures/hvac_packaged_rooftop_heat_pump/README.md): one packaged HP loop/zone | No multizone packaged-HP option. |
| Packaged Rooftop VAV with Hot Water Reheat | Multizone central air; non-fan-powered VAV, packaged DX, shared hot-water central heat/reheat | [hvac_packaged_rooftop_vav_hw_reheat](lib/measures/hvac_packaged_rooftop_vav_hw_reheat/README.md): packaged VAV + gas boiler | Central heat/reheat must use the same boiler. |
| Packaged Rooftop VAV with Electric Reheat | Multizone central air; fan-powered VAV, packaged DX, electric central heat/reheat | [hvac_packaged_rooftop_vav_electric_reheat](lib/measures/hvac_packaged_rooftop_vav_electric_reheat/README.md): parallel fan-powered electric-reheat boxes | **Mapping gap:** distinguish parallel/series boxes in the schema; add series support to the measure if needed. |
| VAV with Hot Water Reheat | Multizone central air; non-fan-powered VAV, chilled water, shared hot-water central heat/reheat | [hvac_vav_hw_reheat](lib/measures/hvac_vav_hw_reheat/README.md): VAV + gas boiler/water-cooled electric chiller | Central heat/reheat must use the same boiler. |
| VAV with Electric Reheat | Multizone central air; fan-powered VAV, chilled water, electric central heat/reheat | [hvac_vav_electric_reheat](lib/measures/hvac_vav_electric_reheat/README.md): parallel fan-powered electric-reheat boxes | **Mapping gap:** distinguish parallel/series boxes in the schema; add series support to the measure if needed. |
| Warm Air Furnace | Single-zone central air; warm-air gas furnace + explicit `NoCooling` | [hvac_warm_air_furnace](lib/measures/hvac_warm_air_furnace/README.md): gas heating-only loop/zone | No split cooling or alternative-fuel option. |
| Ventilation Only | `VentilationType = "Supply only"`; stand-alone, separately linked deliveries with `NoHeating` + `NoCooling` | [hvac_ventilation_only](lib/measures/hvac_ventilation_only/README.md): unconditioned direct-to-zone supply loop | Run after compatible zone equipment; no coils/recovery/exhaust-only service. |
| Dedicated Outdoor Air System | `VentilationType = "Dedicated outdoor air system"`; stand-alone, separately linked deliveries with `NoHeating` + `NoCooling` | [hvac_doas](lib/measures/hvac_doas/README.md): unconditioned direct-to-zone DOAS | The DOAS label alone does not imply unconditioned air; run after zone equipment. |
| Water Loop Heat Pump | Zone heat-pump/DX sources linked to a water-cooled condenser record | [hvac_water_loop_heat_pump](lib/measures/hvac_water_loop_heat_pump/README.md): water-to-air HPs, gas boiler + evaporative fluid cooler | **Mapping gap:** add explicit terminal/shared-loop/fluid-cooler distinctions and corresponding measure options. |
| Ground Source Heat Pump | Zone heat-pump/DX sources linked to `GroundSource`; open-/closed-loop type | [hvac_ground_source_heat_pump](lib/measures/hvac_ground_source_heat_pump/README.md): temperature-source loop approximation | **Mapping gap:** implement physical open-/closed-loop options or explicitly expose/document the approximation mode. |
| VRF Terminal Unit | `FanCoilType = "VRF terminal units"`; VRF DX, linked heating HP, air-cooled condenser | [hvac_vrf](lib/measures/hvac_vrf/README.md): one outdoor unit/source group, zone terminals | `Multi-split` is not the VRF terminal enum; preserve outdoor-unit identity. |
| Chilled Beam | `ConvectionType = "Chilled beam"`; hot/chilled-water sources | [hvac_chilled_beam](lib/measures/hvac_chilled_beam/README.md): active four-pipe beams + conditioned primary air | **Mapping gap:** add active/passive and pipe-arrangement selectors/options. Do not append separate DOAS. |
| Hydronic radiant floor / ceiling | `RadiantType = "Radiant floor or ceiling"`; hot/chilled-water sources | [hvac_radiant](lib/measures/hvac_radiant/README.md): hydronic heating/cooling floors | **Mapping gap:** distinguish floor/ceiling in the schema and add surface-selection options. No named radiant principal enum. |
| Split AC / conventional mini-split HP; two-pipe fan coil; baseboard/radiator | Detailed DX, fan-coil, convection, or radiant subtype | **not mappeable in this gem** | No matching topology builder; do not substitute packaged equipment or four-pipe/radiant-floor systems. |
| Other central-air / plant variants | Conditioned multizone CAV, VAV-no-reheat, dual ducts, steam/district plants, absorption or air-cooled chillers | **not mappeable in this gem** | See the full table for exact unsupported configurations, including terminal/reheat combinations. |
| Conditioned DOAS; HRV/ERV; exhaust; humidity control; natural ventilation | Detailed `OtherHVACSystems` type and linked conditioning sources | **not mappeable in this gem** for equipment creation | Existing heat-recovery equipment can be modified; modifiers do not create it or add DOAS coils. |
| Explicitly no HVAC | Explicit `NoHeating`, `NoCooling`, no delivery mechanism, linked ventilation `None` | **No measure call** | Missing HVAC data is not an explicit no-system declaration. |
| Other / Unknown | Principal label alone supplies no configuration | **not mappeable in this gem from the label alone** | Missing configuration data, not proof that a measure is unavailable; evaluate detailed records. |

For multiple measures, build the matching zone equipment first and unconditioned DOAS/supply ventilation last. Keep each call's exact zone set; central-air systems cannot share zones with a separate DOAS. Hydronic mappings have a conservative single-plant-generating-call constraint because the wrappers cannot bind arbitrary plant IDs. Consult the [complete mapping and grouping requirements](docs/HVAC_MIGRATION.md#applying-one-or-multiple-mappings) before assembling a workflow; an unresolved gap must not silently become a default subtype. Apply validated property modifiers afterward.

## Testing

Run gem-level tests with:

```bash
bundle exec rake spec
```

Run the focused independent-HVAC integration suite with:

```bash
bundle exec rspec spec/tests/independent_hvac_measures_spec.rb
```

Run individual non-HVAC measure tests directly with OpenStudio available:

```bash
bundle exec ruby lib/measures/disable_sizing_runs/tests/disable_sizing_runs_test.rb
bundle exec ruby lib/measures/modify_envelope_insulation/tests/modify_envelope_insulation_test.rb
bundle exec ruby lib/measures/modify_schedules/tests/modify_schedules_test.rb
bundle exec ruby lib/measures/set_infiltration_by_ach/tests/set_infiltration_by_ach_test.rb
```

All 22 independent HVAC measures also have local Minitest suites and checked-in OSM inputs. For example, see [the DOAS tests](lib/measures/hvac_doas/tests/hvac_doas_test.rb) and [their model](lib/measures/hvac_doas/tests/test_model.osm).

Run all independent HVAC unit tests, or one measure:

```bash
bundle exec rake test_hvac
bundle exec ruby lib/measures/hvac_doas/tests/hvac_doas_test.rb
```

Each measure invocation saves input/output models and runner diagnostics under that measure's test output directory, including intentional failures. Assertions inspect the saved-and-reloaded output rather than just checking the runner status. See [Per-measure unit tests](docs/HVAC_MIGRATION.md#per-measure-unit-tests) in the HVAC migration guide for scenarios, artifact locations, fixture maintenance, and test selection.

The legacy `modify_hvac` direct test remains unchanged with the deprecated measure during its compatibility window. The gem-level RSpec suite continues to provide cross-measure integration coverage; `rake spec` and the default Rake task retain their existing behavior.

## Migration Status

All 17 exact HVAC topologies now have one independent operation-aware measure, and all five focused modifiers are implemented. The suite is validated against OpenStudio 3.10 and openstudio-standards 0.8.2. Small local duplication is intentional: each measure is independently packaged and does not invoke another measure or depend on a shared production dispatcher.

The remaining migration step is to remove deprecated `modify_hvac` after consumers switch to the exact-type measures. That removal and the associated version change will be handled as a breaking pre-1.0 release. The BuildingSync mapping gaps above track schema/measure enhancements separately from this measure-splitting migration.

## TODO

- [ ] Remove measures from OpenStudio-Measures to standardize on this location
- [ ] Update measures to code standards
- [ ] Remove deprecated `modify_hvac` after the consumer migration window
- [ ] Validate release candidates against representative multi-zone models and OSW workflows
- [ ] Review and fill out the gemspec file with author and gem description

# Releasing

* Update change log
* Update version in `/lib/openstudio/buildingsync-measures/version.rb`
* Merge down to master
* Release via github
* run `rake release` from master
