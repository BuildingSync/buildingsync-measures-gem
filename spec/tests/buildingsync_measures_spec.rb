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
end
