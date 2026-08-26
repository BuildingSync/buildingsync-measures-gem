class ReplaceWithRadiantHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Replace HVAC with Low-Temperature Radiant'
  def description = 'Replaces HVAC dedicated to selected zones with hydronic low-temperature radiant heating and cooling.'
  def modeler_description = 'Rejects partial shared-loop removal, preserves existing plants, and creates Radiant Slab equipment plus new supporting plants.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', true)
    names.setDisplayName('Target Zone Names')
    names.setDescription('Comma-separated exact thermal-zone names to replace.')
    args << names
    choices = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| choices << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', choices, true)
    template.setDisplayName('Standards Template')
    template.setDescription('openstudio-standards template used to construct the replacement Radiant Slab system.')
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
    without_surfaces = zones.select { |zone| zone.spaces.flat_map(&:surfaces).empty? }
    unless without_surfaces.empty?
      runner.registerError("Radiant replacement requires modeled zone surfaces: #{without_surfaces.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end
    affected = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }
    shared = affected.select { |air_loop| (air_loop.thermalZones.to_a - zones).any? }
    unless shared.empty?
      details = shared.map { |air_loop| "#{air_loop.name}: also serves #{(air_loop.thermalZones.to_a - zones).map { |zone| zone.name.to_s }.join(', ')}" }
      runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      preserved_plants = model.getPlantLoops.size
      removed = zones.sum do |zone|
        equipment = zone.equipment.to_a
        equipment.each(&:remove)
        equipment.size
      end
      affected.each(&:remove)
      unit_handles = (model.getZoneHVACLowTempRadiantVarFlows + model.getZoneHVACLowTempRadiantConstFlows).map { |unit| unit.handle.to_s }
      plant_handles = model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }
      Standard.build(template).model_add_hvac_system(model, 'Radiant Slab', 'NaturalGas', nil, 'Electricity', zones)
      units = (model.getZoneHVACLowTempRadiantVarFlows + model.getZoneHVACLowTempRadiantConstFlows).reject do |unit|
        unit_handles.include?(unit.handle.to_s)
      end
      served_zones = units.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized && !unit.surfaces.empty? }
      missing_zones = zones - served_zones.uniq
      unless missing_zones.empty?
        runner.registerError("Radiant replacement did not assign radiant surfaces in: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      created_plants = model.getPlantLoops.count { |plant_loop| !plant_handles.include?(plant_loop.handle.to_s) }
      runner.registerFinalCondition(
        "Removed #{affected.size} air loops and #{removed} zone HVAC objects; created #{units.size} radiant systems and " \
        "#{created_plants} plants; preserved #{preserved_plants} existing plants."
      )
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Radiant replacement failed: #{e.message}")
      false
    end
  end
end

ReplaceWithRadiantHvac.new.registerWithApplication
