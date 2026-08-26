class ReplaceWithVentilationOnlyHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Replace HVAC with Ventilation-Only Systems'
  def description = 'Replaces HVAC dedicated to selected zones with ventilation-only air systems.'
  def modeler_description = 'Rejects partial shared-loop removal, preserves existing plants, and directly creates ventilation-only topology.'

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
    zones = model.getThermalZones.select { |zone| requested.include?(zone.name.to_s) }
    missing = requested - zones.map { |zone| zone.name.to_s }
    unless missing.empty?
      runner.registerError("Thermal zones not found: #{missing.join(', ')}")
      return false
    end
    affected = model.getAirLoopHVACs.select { |loop| (loop.thermalZones.to_a & zones).any? }
    shared = affected.select { |loop| (loop.thermalZones.to_a - zones).any? }
    unless shared.empty?
      details = shared.map { |loop| "#{loop.name}: also serves #{(loop.thermalZones.to_a - zones).map { |zone| zone.name.to_s }.join(', ')}" }
      runner.registerError("Replacement would partially remove shared air loops. Expand the target scope: #{details.join('; ')}")
      return false
    end

    begin
      preserved_plants = model.getPlantLoops.size
      removed = zones.sum do |zone|
        equipment = zone.equipment.to_a
        equipment.each(&:remove)
        equipment.size
      end
      affected.each(&:remove)
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName('Replacement Ventilation Only Air Loop')
      controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
      outdoor_air_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller)
      outdoor_air_system.addToNode(air_loop.supplyInletNode)
      fan = OpenStudio::Model::FanSystemModel.new(model)
      fan.addToNode(air_loop.supplyOutletNode)
      zones.each { |zone| air_loop.addBranchForZone(zone) }
      unserved = zones - air_loop.thermalZones.to_a
      unless unserved.empty?
        runner.registerError("Ventilation-only replacement did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      runner.registerFinalCondition("Removed #{affected.size} loops and #{removed} zone objects; created one ventilation-only loop using workflow template #{template} and preserved #{preserved_plants} plants.")
      true
    rescue StandardError => e
      runner.registerError("Ventilation-only replacement failed: #{e.message}")
      false
    end
  end
end

ReplaceWithVentilationOnlyHvac.new.registerWithApplication
