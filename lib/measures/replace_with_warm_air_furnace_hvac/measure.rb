class ReplaceWithWarmAirFurnaceHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Replace HVAC with Warm-Air Furnace'
  def description = 'Replaces HVAC dedicated to selected zones with warm-air furnace systems.'
  def modeler_description = 'Rejects partial shared-loop removal, removes selected-zone equipment and dedicated loops, and creates Forced Air Furnace systems.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    zone_names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', true)
    zone_names.setDisplayName('Target Zone Names')
    zone_names.setDescription('Comma-separated exact thermal-zone names to replace.')
    args << zone_names
    templates = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| templates << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', templates, true)
    template.setDisplayName('Standards Template')
    template.setDescription('openstudio-standards template used to construct replacement warm-air furnace systems.')
    template.setDefaultValue('90.1-2019')
    args << template
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested = runner.getStringArgumentValue('target_zone_names', user_arguments).split(',').map(&:strip).reject(&:empty?).uniq
    if requested.empty?
      runner.registerError('target_zone_names must contain at least one exact thermal-zone name.')
      return false
    end
    template = runner.getStringArgumentValue('standards_template', user_arguments)
    zones = model.getThermalZones.select { |zone| requested.include?(zone.name.to_s) }
    missing = requested - zones.map { |zone| zone.name.to_s }
    unless missing.empty?
      runner.registerError("Thermal zones not found: #{missing.join(', ')}")
      return false
    end
    affected = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }
    shared = affected.select { |air_loop| (air_loop.thermalZones.to_a - zones).any? }
    unless shared.empty?
      details = shared.map do |air_loop|
        remaining = air_loop.thermalZones.to_a - zones
        "#{air_loop.name}: also serves #{remaining.map { |zone| zone.name.to_s }.join(', ')}"
      end
      runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      removed_equipment = zones.sum do |zone|
        equipment = zone.equipment.to_a
        equipment.each(&:remove)
        equipment.size
      end
      affected.each(&:remove)
      loop_handles = model.getAirLoopHVACs.map { |air_loop| air_loop.handle.to_s }
      unit_handles = model.getZoneHVACUnitHeaters.map { |unit| unit.handle.to_s }
      Standard.build(template).model_add_hvac_system(model, 'Forced Air Furnace', 'NaturalGas', nil, 'Electricity', zones)
      created_loops = model.getAirLoopHVACs.reject { |air_loop| loop_handles.include?(air_loop.handle.to_s) }
      created_units = model.getZoneHVACUnitHeaters.reject { |unit| unit_handles.include?(unit.handle.to_s) }
      served_zones = created_loops.flat_map(&:thermalZones)
      served_zones.concat(created_units.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized })
      missing_zones = zones - served_zones.uniq
      unless missing_zones.empty?
        runner.registerError("Warm-air furnace replacement did not serve: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      runner.registerFinalCondition(
        "Removed #{affected.size} dedicated air loops and #{removed_equipment} zone HVAC objects; " \
        "created #{created_loops.size} furnace loops and #{created_units.size} unit heaters. Existing plant loops were preserved."
      )
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Warm-air furnace replacement failed: #{e.message}")
      false
    end
  end
end

ReplaceWithWarmAirFurnaceHvac.new.registerWithApplication
