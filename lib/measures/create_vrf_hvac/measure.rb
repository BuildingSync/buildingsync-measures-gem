class CreateVrfHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Create VRF HVAC'
  def description = 'Adds a variable-refrigerant-flow system to unserved target zones.'
  def modeler_description = 'Uses the openstudio-standards VRF system and verifies that newly created terminals serve every selected zone.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    zone_names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', false)
    zone_names.setDisplayName('Target Zone Names')
    zone_names.setDescription('Comma-separated exact thermal-zone names. Blank selects all thermal zones.')
    zone_names.setDefaultValue('')
    args << zone_names
    templates = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| templates << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', templates, true)
    template.setDisplayName('Standards Template')
    template.setDescription('openstudio-standards template used to construct the VRF system.')
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
    served = model.getAirLoopHVACs.flat_map(&:thermalZones).uniq
    conflicts = zones.select { |zone| !zone.equipment.empty? || served.include?(zone) }
    unless conflicts.empty?
      runner.registerError("VRF creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      before = model.getAirConditionerVariableRefrigerantFlows.map { |vrf| vrf.handle.to_s }
      Standard.build(template).model_add_hvac_system(model, 'VRF', 'NaturalGas', nil, 'Electricity', zones)
      created = model.getAirConditionerVariableRefrigerantFlows.reject { |vrf| before.include?(vrf.handle.to_s) }
      terminals = created.flat_map { |vrf| vrf.terminals.to_a }
      served_zones = terminals.filter_map { |terminal| terminal.thermalZone.get if terminal.thermalZone.is_initialized }
      missing_zones = zones - served_zones.uniq
      unless missing_zones.empty?
        runner.registerError("VRF creation did not serve: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      runner.registerFinalCondition("Created #{created.size} VRF outdoor units and #{terminals.size} terminals for #{zones.size} zones using #{template}.")
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("VRF creation failed: #{e.message}")
      false
    end
  end
end

CreateVrfHvac.new.registerWithApplication
