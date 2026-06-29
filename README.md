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

Currently migrated measures:

- `disable_sizing_runs` - disables sizing-period simulation and keeps weather-file run periods enabled.
- `modify_envelope_insulation` - adjusts exterior wall, roof, and floor construction insulation to target R-values or U-values.
- `modify_hvac` - maps BuildingSync HVAC system inputs to OpenStudio HVAC modifications and synthesis behavior.
- `modify_schedules` - creates or replaces OpenStudio schedules from BuildingSync-aligned schedule payloads.
- `set_infiltration_by_ach` - updates existing infiltration objects to a natural ACH value, with optional ACH50 conversion.

Run gem-level tests with:

```bash
bundle exec rake spec
```

Run migrated measure tests directly with OpenStudio available:

```bash
bundle exec ruby lib/measures/disable_sizing_runs/tests/disable_sizing_runs_test.rb
bundle exec ruby lib/measures/modify_envelope_insulation/tests/modify_envelope_insulation_test.rb
bundle exec ruby lib/measures/modify_hvac/tests/modify_hvac_test.rb
bundle exec ruby lib/measures/modify_schedules/tests/modify_schedules_test.rb
bundle exec ruby lib/measures/set_infiltration_by_ach/tests/set_infiltration_by_ach_test.rb
```

The copied measure tests are retained for hardening, but they are not yet required by CI. The current CI gate verifies gem specs and Ruby syntax while the migrated tests and OpenStudio measure-tester/RuboCop configuration are normalized.

## Migration Status

Initial migration from personal development has copied the five active model measures into this gem. Remaining work is to verify behavior under the OpenStudio 3.10 CI container, factor any duplicated shared logic into `lib/openstudio/buildingsync_measures`, and port the OSW integration harness if needed.

## TODO

- [ ] Remove measures from OpenStudio-Measures to standardize on this location
- [ ] Update measures to code standards
- [ ] Review and fill out the gemspec file with author and gem description

# Releasing

* Update change log
* Update version in `/lib/openstudio/buildingsync-measures/version.rb`
* Merge down to master
* Release via github
* run `rake release` from master
