class ReplaceWithVrfHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Replace HVAC with VRF'
  def description = 'Replaces HVAC dedicated to selected zones with a variable-refrigerant-flow system.'
  def modeler_description = 'Rejects partial shared air-loop or VRF outdoor-unit removal, removes selected-zone equipment, and creates a VRF system.'

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
    template.setDescription('openstudio-standards template used to construct the replacement VRF system.')
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

    affected_loops = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }
    shared_loops = affected_loops.select { |air_loop| (air_loop.thermalZones.to_a - zones).any? }
    unless shared_loops.empty?
      details = shared_loops.map do |air_loop|
        remaining = air_loop.thermalZones.to_a - zones
        "#{air_loop.name}: also serves #{remaining.map { |zone| zone.name.to_s }.join(', ')}"
      end
      runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
      return false
    end

    existing_vrf_zones = lambda do |vrf|
      vrf.terminals.filter_map { |terminal| terminal.thermalZone.get if terminal.thermalZone.is_initialized }.uniq
    end
    affected_vrf = model.getAirConditionerVariableRefrigerantFlows.select { |vrf| (existing_vrf_zones.call(vrf) & zones).any? }
    shared_vrf = affected_vrf.select { |vrf| (existing_vrf_zones.call(vrf) - zones).any? }
    unless shared_vrf.empty?
      details = shared_vrf.map do |vrf|
        remaining = existing_vrf_zones.call(vrf) - zones
        "#{vrf.name}: also serves #{remaining.map { |zone| zone.name.to_s }.join(', ')}"
      end
      runner.registerError("Replacement would partially remove shared VRF outdoor units. Expand the target scope: #{details.join('; ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      removed_equipment = zones.sum do |zone|
        equipment = zone.equipment.to_a
        equipment.each(&:remove)
        equipment.size
      end
      affected_loops.each(&:remove)
      affected_vrf.each(&:remove)
      before = model.getAirConditionerVariableRefrigerantFlows.map { |vrf| vrf.handle.to_s }
      Standard.build(template).model_add_hvac_system(model, 'VRF', 'NaturalGas', nil, 'Electricity', zones)
      created = model.getAirConditionerVariableRefrigerantFlows.reject { |vrf| before.include?(vrf.handle.to_s) }
      terminals = created.flat_map { |vrf| vrf.terminals.to_a }
      served_zones = terminals.filter_map { |terminal| terminal.thermalZone.get if terminal.thermalZone.is_initialized }
      missing_zones = zones - served_zones.uniq
      unless missing_zones.empty?
        runner.registerError("VRF replacement did not serve: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      runner.registerFinalCondition(
        "Removed #{affected_loops.size} air loops, #{affected_vrf.size} VRF outdoor units, and #{removed_equipment} zone HVAC objects; " \
        "created #{created.size} VRF outdoor units and #{terminals.size} terminals. Existing plant loops were preserved."
      )
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("VRF replacement failed: #{e.message}")
      false
    end
  end
end

ReplaceWithVrfHvac.new.registerWithApplication
