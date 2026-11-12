# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'
require 'rexml/document'

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
      hvac_chilled_beam
      hvac_doas
      hvac_four_pipe_fan_coil
      hvac_ground_source_heat_pump
      hvac_packaged_rooftop_ac
      hvac_packaged_rooftop_heat_pump
      hvac_packaged_rooftop_vav_electric_reheat
      hvac_packaged_rooftop_vav_hw_reheat
      hvac_ptac
      hvac_pthp
      hvac_radiant
      hvac_vav_electric_reheat
      hvac_vav_hw_reheat
      hvac_ventilation_only
      hvac_vrf
      hvac_warm_air_furnace
      hvac_water_loop_heat_pump
      modify_envelope_insulation
      modify_existing_air_loop_controls
      modify_existing_heat_recovery
      modify_existing_hvac_equipment_efficiencies
      modify_existing_plant_equipment
      modify_existing_plant_loop_temperatures
      modify_hvac
      modify_schedules
      set_infiltration_by_ach
    ]

    expected_measures.each do |measure_name|
      measure_dir = File.join(instance.measures_dir, measure_name)

      expect(File.directory?(measure_dir)).to be true
      expect(File.file?(File.join(measure_dir, 'measure.rb'))).to be true
      expect(File.file?(File.join(measure_dir, 'measure.xml'))).to be true
    end
  end

  it 'uses unique measure UIDs' do
    instance = OpenStudio::BuildingsyncMeasures::BuildingsyncMeasures.new
    uid_sources = Dir.glob(File.join(instance.measures_dir, '*', 'measure.xml')).map do |xml_path|
      document = REXML::Document.new(File.read(xml_path))
      [document.elements['measure/uid']&.text, xml_path]
    end
    missing_uid_paths = uid_sources.select { |uid, _path| uid.nil? || uid.empty? }.map(&:last)
    duplicate_uids = uid_sources.group_by(&:first).select { |uid, sources| uid && sources.size > 1 }.keys

    expect(missing_uid_paths).to be_empty
    expect(duplicate_uids).to be_empty
  end

  it 'packages documentation and BuildingSync mappings for independent HVAC measures' do
    instance = OpenStudio::BuildingsyncMeasures::BuildingsyncMeasures.new
    topology_names = %w[
      hvac_chilled_beam hvac_doas hvac_four_pipe_fan_coil hvac_ground_source_heat_pump
      hvac_packaged_rooftop_ac hvac_packaged_rooftop_heat_pump
      hvac_packaged_rooftop_vav_electric_reheat hvac_packaged_rooftop_vav_hw_reheat
      hvac_ptac hvac_pthp hvac_radiant hvac_vav_electric_reheat hvac_vav_hw_reheat
      hvac_ventilation_only hvac_vrf hvac_warm_air_furnace hvac_water_loop_heat_pump
    ]
    independent_dirs = topology_names.map { |name| File.join(instance.measures_dir, name) }
    independent_dirs.concat(Dir.glob(File.join(instance.measures_dir, 'modify_existing_*')))

    independent_dirs.each do |measure_dir|
      readme_path = File.join(measure_dir, 'README.md')
      license_path = File.join(measure_dir, 'LICENSE.md')
      expect(File.file?(readme_path)).to be true
      expect(File.file?(license_path)).to be true
      expect(File.read(readme_path)).to include('BuildingSync mapping')
    end
  end
end
