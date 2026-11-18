require 'rspec/core/rake_task'
require 'rake/testtask'

RSpec::Core::RakeTask.new(:spec)

Rake::TestTask.new(:test_hvac) do |test|
	test.description = 'Run all per-measure HVAC unit tests (or select one with TEST=path/to/test.rb)'
  test.pattern = 'lib/measures/{hvac_*,modify_existing_*,apply_hvac_topology_to_zone_scope,apply_hvac_modifier_to_object_scope,apply_standard_hvac_sizing_and_efficiency}/tests/*_test.rb'
	test.warning = false
end

desc 'Regenerate the checked-in HVAC test models using the installed OpenStudio SDK'
task :hvac_test_fixtures do
	ruby 'lib/openstudio/buildingsync_measures/test_support/generate_hvac_fixtures.rb'
end

task default: :spec