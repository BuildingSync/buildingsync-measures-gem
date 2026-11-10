# Per-measure HVAC unit tests

All 17 independent HVAC topology measures and five `modify_existing_*` HVAC modifiers contain a local Minitest entry point and a checked-in OSM fixture. The deprecated `modify_hvac` suite is not part of this new test group.

Examples:

- [DOAS test entry point](../lib/measures/hvac_doas/tests/hvac_doas_test.rb) and [fixture](../lib/measures/hvac_doas/tests/test_model.osm).
- [Plant-equipment modifier tests](../lib/measures/modify_existing_plant_equipment/tests/modify_existing_plant_equipment_test.rb) and [fixture](../lib/measures/modify_existing_plant_equipment/tests/test_model.osm).
- [Radiant tests](../lib/measures/hvac_radiant/tests/hvac_radiant_test.rb), including a zone-without-surfaces error.
- [Heat-recovery tests](../lib/measures/modify_existing_heat_recovery/tests/modify_existing_heat_recovery_test.rb), including zero effectiveness and re-enabling recovery.

## Running tests

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

## What is checked

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

Topology-specific assertions inspect terminal/unit types, zone connections, heating/cooling coil types and plant connections. Additional tests cover DOAS/ventilation priority and elimination of duplicate zone-unit outdoor air, radiant surface requirements, and rejection of partial VRF outdoor-unit replacement.

Modifier suites check:

- Every supported plant capacity/efficiency property, including kW-to-W and ton-to-W conversion.
- All eight equipment efficiency metrics, plus both speeds of two-speed DX cooling coils.
- Sensible/latent effectiveness in heating and cooling at both airflow levels, inclusive 0 and 1 boundaries, repeated disabling/restoration, and unsupported effectiveness curves.
- Supply-air temperatures, all six economizer types, combined changes, no-op/NA behavior, missing electronic-enthalpy curves, and warnings for loops without outdoor air.
- Heating, chilled-water, and radiant loop design temperatures.
- Exact-name scope, multiple/duplicate names, preservation of unselected objects, missing names, invalid numeric bounds where defined, and incompatible object/property combinations.

Every intentional rejection verifies the complete serialized model is unchanged, rather than only checking an object count. Supported mixed-object updates verify the incompatible object is preserved and a warning is recorded.

These are model-editing unit tests with forward-translation smoke checks, **not** annual energy, sizing, comfort, or equipment-performance validation. The existing RSpec suite covers additional cross-measure interactions and orphaned-plant cleanup.

## Inspecting artifacts

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

## Fixtures and maintenance

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