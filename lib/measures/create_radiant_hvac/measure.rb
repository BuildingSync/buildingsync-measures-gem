class CreateRadiantHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Create Low-Temperature Radiant HVAC'
  def description = 'Adds hydronic low-temperature radiant heating and cooling to unserved target zones.'
  def modeler_description = 'Uses the openstudio-standards Radiant Slab system and verifies new radiant equipment, surface assignment, and plant creation.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', false)
    names.setDisplayName('Target Zone Names')
    names.setDescription('Comma-separated exact thermal-zone names. Blank selects all thermal zones.')
    names.setDefaultValue('')
    args << names
    choices = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| choices << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', choices, true)
    template.setDisplayName('Standards Template')
    template.setDescription('openstudio-standards template used to construct the Radiant Slab system.')
    template.setDefaultValue('90.1-2019')
    args << template
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested = runner.getStringArgumentValue('target_zone_names', user_arguments).split(',').map(&:strip).reject(&:empty?).uniq
    template = runner.getStringArgumentValue('standards_template', user_arguments)
    zones = requested.empty? ? model.getThermalZones.to_a : model.getThermalZones.select { |zone| requested.include?(zone.name.to_s) }
    missing = requested - zones.map { |zone| zone.name.to_s }
    unless missing.empty?
      runner.registerError("Thermal zones not found: #{missing.join(', ')}")
      return false
    end
    if zones.empty?
      runner.registerError('No target thermal zones were found.')
      return false
    end
    without_surfaces = zones.select { |zone| zone.spaces.flat_map(&:surfaces).empty? }
    unless without_surfaces.empty?
      runner.registerError("Radiant creation requires modeled zone surfaces: #{without_surfaces.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end
    served = model.getAirLoopHVACs.flat_map(&:thermalZones).uniq
    conflicts = zones.select { |zone| !zone.equipment.empty? || served.include?(zone) }
    unless conflicts.empty?
      runner.registerError("Radiant creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      unit_handles = (model.getZoneHVACLowTempRadiantVarFlows + model.getZoneHVACLowTempRadiantConstFlows).map { |unit| unit.handle.to_s }
      plant_handles = model.getPlantLoops.map { |plant_loop| plant_loop.handle.to_s }
      Standard.build(template).model_add_hvac_system(model, 'Radiant Slab', 'NaturalGas', nil, 'Electricity', zones)
      units = (model.getZoneHVACLowTempRadiantVarFlows + model.getZoneHVACLowTempRadiantConstFlows).reject do |unit|
        unit_handles.include?(unit.handle.to_s)
      end
      served_zones = units.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized && !unit.surfaces.empty? }
      missing_zones = zones - served_zones.uniq
      unless missing_zones.empty?
        runner.registerError("Radiant creation did not assign radiant surfaces in: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      created_plants = model.getPlantLoops.count { |plant_loop| !plant_handles.include?(plant_loop.handle.to_s) }
      runner.registerFinalCondition("Created #{units.size} radiant systems and #{created_plants} plant loops for #{zones.size} zones using #{template}.")
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("Radiant creation failed: #{e.message}")
      false
    end
  end
end

CreateRadiantHvac.new.registerWithApplication
