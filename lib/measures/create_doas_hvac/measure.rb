class CreateDoasHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Create Dedicated Outdoor Air System'
  def description = 'Adds dedicated outdoor air systems to unserved target zones.'
  def modeler_description = 'Creates a dedicated outdoor-air loop and fan directly, then verifies target-zone coverage.'

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
    template.setDescription('Workflow template retained for consistent create-measure contracts; DOAS topology is constructed directly.')
    template.setDefaultValue('90.1-2019')
    args << template
    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested = runner.getStringArgumentValue('target_zone_names', user_arguments).split(',').map(&:strip).reject(&:empty?).uniq
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
      runner.registerError("DOAS creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end

    begin
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName('Dedicated Outdoor Air System')
      air_loop.sizingSystem.setTypeofLoadtoSizeOn('VentilationRequirement')
      controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
      outdoor_air_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller)
      outdoor_air_system.addToNode(air_loop.supplyInletNode)
      fan = OpenStudio::Model::FanSystemModel.new(model)
      fan.addToNode(air_loop.supplyOutletNode)
      zones.each { |zone| air_loop.addBranchForZone(zone) }
      unserved = zones - air_loop.thermalZones.to_a
      unless unserved.empty?
        runner.registerError("DOAS creation did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      runner.registerFinalCondition("Created one DOAS loop for #{zones.size} zones using workflow template #{template}.")
      true
    rescue StandardError => e
      runner.registerError("DOAS creation failed: #{e.message}")
      false
    end
  end
end

CreateDoasHvac.new.registerWithApplication
