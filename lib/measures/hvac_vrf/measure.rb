class HvacVrf < OpenStudio::Measure::ModelMeasure
  def name = 'VRF HVAC'
  def description = 'Creates VRF systems in unserved zones or replaces HVAC dedicated to selected zones.'
  def modeler_description = 'Uses one VRF synthesis path; replacement rejects partial shared air-loop and VRF outdoor-unit removal.'

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    operations = OpenStudio::StringVector.new
    %w[create replace].each { |value| operations << value }
    operation = OpenStudio::Measure::OSArgument.makeChoiceArgument('operation', operations, true)
    operation.setDisplayName('Operation')
    operation.setDefaultValue('create')
    args << operation
    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', false)
    names.setDisplayName('Target Zone Names')
    names.setDescription('Comma-separated exact thermal-zone names. Blank selects all zones for create; replace requires explicit names.')
    names.setDefaultValue('')
    args << names
    choices = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| choices << value }
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', choices, true)
    template.setDisplayName('Standards Template')
    template.setDefaultValue('90.1-2019')
    args << template
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    operation = runner.getStringArgumentValue('operation', user_arguments)
    requested = runner.getStringArgumentValue('target_zone_names', user_arguments).split(',').map(&:strip).reject(&:empty?).uniq
    if operation == 'replace' && requested.empty?
      runner.registerError('Replace requires at least one exact target_zone_names value.')
      return false
    end
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

    dedicated_outdoor_air = lambda do |air_loop|
      air_loop.sizingSystem.typeofLoadtoSizeOn == 'VentilationRequirement' &&
        air_loop.demandComponents.count { |component| component.to_AirTerminalSingleDuctConstantVolumeNoReheat.is_initialized } == air_loop.thermalZones.size
    end
    doas_loops, affected_loops = model.getAirLoopHVACs.select { |air_loop| (air_loop.thermalZones.to_a & zones).any? }.partition(&dedicated_outdoor_air)
    doas_handles = doas_loops.flat_map { |air_loop| air_loop.demandComponents.map { |component| component.handle.to_s } }
    zone_equipment = ->(zone) { zone.equipment.reject { |equipment| doas_handles.include?(equipment.handle.to_s) } }
    vrf_zones = lambda do |vrf|
      vrf.terminals.filter_map { |terminal| terminal.thermalZone.get if terminal.thermalZone.is_initialized }.uniq
    end
    affected_vrf = model.getAirConditionerVariableRefrigerantFlows.select { |vrf| (vrf_zones.call(vrf) & zones).any? }
    if operation == 'create'
      conflicts = zones.select { |zone| !zone_equipment.call(zone).empty? || affected_loops.any? { |air_loop| air_loop.thermalZones.include?(zone) } }
      unless conflicts.empty?
        runner.registerError("VRF creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
    else
      shared_loops = affected_loops.select { |air_loop| (air_loop.thermalZones.to_a - zones).any? }
      unless shared_loops.empty?
        details = shared_loops.map { |air_loop| "#{air_loop.name}: also serves #{(air_loop.thermalZones.to_a - zones).map { |zone| zone.name.to_s }.join(', ')}" }
        runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
        return false
      end
      shared_vrf = affected_vrf.select { |vrf| (vrf_zones.call(vrf) - zones).any? }
      unless shared_vrf.empty?
        details = shared_vrf.map { |vrf| "#{vrf.name}: also serves #{(vrf_zones.call(vrf) - zones).map { |zone| zone.name.to_s }.join(', ')}" }
        runner.registerError("Replacement would partially remove shared VRF outdoor units. Expand the target scope: #{details.join('; ')}")
        return false
      end
    end

    begin
      require 'openstudio-standards'
      removed = 0
      if operation == 'replace'
        removed = zones.sum do |zone|
          equipment = zone_equipment.call(zone).to_a
          equipment.each(&:remove)
          equipment.size
        end
        affected_loops.each(&:remove)
        affected_vrf.each(&:remove)
      end
      before = model.getAirConditionerVariableRefrigerantFlows.map { |vrf| vrf.handle.to_s }
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      unless Standard.build(template).model_add_hvac_system(model, 'VRF', 'NaturalGas', nil, 'Electricity', zones)
        runner.registerError("openstudio-standards failed to add 'VRF' for #{operation}.")
        return false
      end
      created = model.getAirConditionerVariableRefrigerantFlows.reject { |vrf| before.include?(vrf.handle.to_s) }
      terminals = created.flat_map { |vrf| vrf.terminals.to_a }
      served = terminals.filter_map { |terminal| terminal.thermalZone.get if terminal.thermalZone.is_initialized }
      unserved = zones - served.uniq
      unless unserved.empty?
        runner.registerError("VRF #{operation} did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      summary = "Created #{created.size} VRF outdoor units and #{terminals.size} terminals for #{zones.size} zones using #{template}."
      summary = "Removed #{affected_loops.size} air loops, #{affected_vrf.size} VRF outdoor units, and #{removed} zone HVAC objects; #{summary} Existing plant loops were preserved." if operation == 'replace'
      runner.registerFinalCondition(summary)
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("VRF #{operation} failed: #{e.message}")
      false
    end
  end
end

HvacVrf.new.registerWithApplication