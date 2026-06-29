# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'

RSpec.describe OpenStudio::BuildingsyncMeasures do
  it 'has a version number' do
    expect(OpenStudio::BuildingsyncMeasures::VERSION).not_to be nil
  end

  it 'has a measures directory' do
    instance = OpenStudio::BuildingsyncMeasures::BuildingsyncMeasures.new
    expect(File.exist?(instance.measures_dir)).to be true
  end

  it 'includes migrated measures' do
    instance = OpenStudio::BuildingsyncMeasures::BuildingsyncMeasures.new
    expected_measures = %w[
      disable_sizing_runs
      modify_envelope_insulation
      modify_hvac
      modify_schedules
      set_infiltration_by_ach
    ]

    expected_measures.each do |measure_name|
      measure_dir = File.join(instance.measures_dir, measure_name)

      expect(File.directory?(measure_dir)).to be true
      expect(File.file?(File.join(measure_dir, 'measure.rb'))).to be true
      expect(File.file?(File.join(measure_dir, 'measure.xml'))).to be true
      expect(File.file?(File.join(measure_dir, 'README.md'))).to be true
    end
  end
end
