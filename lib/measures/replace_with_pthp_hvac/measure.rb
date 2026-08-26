class ReplaceWithPthpHvac < OpenStudio::Measure::ModelMeasure
  def name
    'Replace HVAC with PTHP'
  end

  def description
    'Removes HVAC dedicated to selected zones and installs packaged terminal heat pumps.'
  end

  def modeler_description
    'Rejects partial removal of shared air loops, preserves unrelated HVAC and plant loops, then creates PTHP equipment with openstudio-standards.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    target_zone_names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', true)
    target_zone_names.setDisplayName('Target Zone Names')
    target_zone_names.setDescription('Comma-separated exact thermal-zone names to replace. At least one name is required.')
    args << target_zone_names

    templates = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| templates << value }
    standards_template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', templates, true)
    standards_template.setDisplayName('Standards Template')
    standards_template.setDescription('openstudio-standards template used to construct the replacement PTHP system.')
    standards_template.setDefaultValue('90.1-2019')
    args << standards_template

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested_names = runner.getStringArgumentValue('target_zone_names', user_arguments)
                            .split(',').map(&:strip).reject(&:empty?).uniq
    if requested_names.empty?
      runner.registerError('target_zone_names must contain at least one exact thermal-zone name.')
      return false
    end
    standards_template = runner.getStringArgumentValue('standards_template', user_arguments)
    zones = model.getThermalZones.select { |zone| requested_names.include?(zone.name.to_s) }
    missing_names = requested_names - zones.map { |zone| zone.name.to_s }
    unless missing_names.empty?
      runner.registerError("Thermal zones not found: #{missing_names.join(', ')}")
      return false
    end

    affected_air_loops = model.getAirLoopHVACs.select do |air_loop|
      (air_loop.thermalZones.to_a & zones).any?
    end
    shared_air_loops = affected_air_loops.select do |air_loop|
      (air_loop.thermalZones.to_a - zones).any?
    end
    unless shared_air_loops.empty?
      details = shared_air_loops.map do |air_loop|
        remaining = air_loop.thermalZones.to_a - zones
        "#{air_loop.name}: also serves #{remaining.map { |zone| zone.name.to_s }.join(', ')}"
      end
      runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      removed_zone_equipment = zones.sum do |zone|
        equipment = zone.equipment.to_a
        equipment.each(&:remove)
        equipment.size
      end
      affected_air_loops.each(&:remove)

      before_handles = model.getZoneHVACPackagedTerminalHeatPumps.map { |unit| unit.handle.to_s }
      Standard.build(standards_template).model_add_hvac_system(
        model, 'PTHP', 'NaturalGas', nil, 'Electricity', zones
      )
      created = model.getZoneHVACPackagedTerminalHeatPumps.reject do |unit|
        before_handles.include?(unit.handle.to_s)
      end
      created_zones = created.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized }
      missing_zones = zones - created_zones
      unless missing_zones.empty?
        runner.registerError("PTHP replacement did not produce equipment for: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end

      runner.registerFinalCondition(
        "Removed #{affected_air_loops.size} dedicated air loops and #{removed_zone_equipment} zone HVAC objects; " \
        "created #{created.size} PTHP units for #{zones.size} zones. Existing plant loops were preserved."
      )
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("PTHP replacement failed: #{e.message}")
      false
    end
  end
end

ReplaceWithPthpHvac.new.registerWithApplication
