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

See the [HVAC measure index and migration guide](docs/HVAC_MIGRATION.md) for the complete topology table, legacy `modify_hvac` mappings, BuildingSync workflow responsibilities, and known limitations. The monolithic `modify_hvac` measure is retained temporarily for backward compatibility but is deprecated for new workflows.

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

The legacy `modify_hvac` direct test remains with the deprecated measure during its compatibility window. The gem-level RSpec suite is the validation entry point for the independent HVAC measures.

## Migration Status

All 17 exact HVAC topologies now have one independent operation-aware measure, and all five focused modifiers are implemented. The suite is validated against OpenStudio 3.10 and openstudio-standards 0.8.2. Small local duplication is intentional: each measure is independently packaged and does not invoke another measure or depend on a shared production dispatcher.

The remaining migration step is to remove deprecated `modify_hvac` after consumers switch to the exact-type measures. That removal and the associated version change will be handled as a breaking pre-1.0 release.

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
