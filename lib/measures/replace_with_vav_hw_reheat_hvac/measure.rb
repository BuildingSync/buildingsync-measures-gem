class ReplaceWithVavHwReheatHvac < OpenStudio::Measure::ModelMeasure
  def name = 'Replace HVAC with VAV and Hot Water Reheat'
  def description = 'Replaces HVAC dedicated to selected zones with built-up VAV and hot-water reheat.'
  def modeler_description = 'Rejects partial shared-loop removal, preserves existing plants, and creates VAV Reheat.'

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
      require 'openstudio-standards'
      preserved_plants = model.getPlantLoops.size
      removed = zones.sum do |zone|
        equipment = zone.equipment.to_a
        equipment.each(&:remove)
        equipment.size
      end
      affected.each(&:remove)
      before = model.getAirLoopHVACs.map { |loop| loop.handle.to_s }
      template = runner.getStringArgumentValue('standards_template', user_arguments)
      Standard.build(template).model_add_hvac_system(model, 'VAV Reheat', 'NaturalGas', nil, 'Electricity', zones)
      created = model.getAirLoopHVACs.reject { |loop| before.include?(loop.handle.to_s) }
      unserved = zones - created.flat_map(&:thermalZones).uniq
      unless unserved.empty?
        runner.registerError("VAV Reheat replacement did not serve: #{unserved.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end
      runner.registerFinalCondition("Removed #{affected.size} loops and #{removed} zone objects; created #{created.size} VAV Reheat loops and preserved #{preserved_plants} plants.")
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("VAV Reheat replacement failed: #{e.message}")
      false
    end
  end
end

ReplaceWithVavHwReheatHvac.new.registerWithApplication
