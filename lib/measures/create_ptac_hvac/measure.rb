class CreatePtacHvac < OpenStudio::Measure::ModelMeasure
  def name
    'Create PTAC HVAC'
  end

  def description
    'Adds packaged terminal air conditioners to unserved target zones.'
  end

  def modeler_description
    'Uses openstudio-standards to create PTAC equipment. Fails when selected zones already have zone HVAC or an air-loop connection.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    target_zone_names = OpenStudio::Measure::OSArgument.makeStringArgument('target_zone_names', false)
    target_zone_names.setDisplayName('Target Zone Names')
    target_zone_names.setDescription('Comma-separated exact thermal-zone names. Blank selects all thermal zones.')
    target_zone_names.setDefaultValue('')
    args << target_zone_names

    templates = OpenStudio::StringVector.new
    %w[90.1-2013 90.1-2016 90.1-2019].each { |value| templates << value }
    standards_template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', templates, true)
    standards_template.setDisplayName('Standards Template')
    standards_template.setDescription('openstudio-standards template used to construct the PTAC system.')
    standards_template.setDefaultValue('90.1-2019')
    args << standards_template

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    requested_names = runner.getStringArgumentValue('target_zone_names', user_arguments)
                            .split(',').map(&:strip).reject(&:empty?).uniq
    standards_template = runner.getStringArgumentValue('standards_template', user_arguments)
    zones = requested_names.empty? ? model.getThermalZones.to_a : model.getThermalZones.select do |zone|
      requested_names.include?(zone.name.to_s)
    end
    missing_names = requested_names - zones.map { |zone| zone.name.to_s }
    unless missing_names.empty?
      runner.registerError("Thermal zones not found: #{missing_names.join(', ')}")
      return false
    end
    if zones.empty?
      runner.registerError('No target thermal zones were found.')
      return false
    end

    served_by_air_loop = model.getAirLoopHVACs.flat_map(&:thermalZones).uniq
    conflicts = zones.select { |zone| !zone.equipment.empty? || served_by_air_loop.include?(zone) }
    unless conflicts.empty?
      runner.registerError("PTAC creation requires unserved zones. Conflicts: #{conflicts.map { |zone| zone.name.to_s }.join(', ')}")
      return false
    end

    begin
      require 'openstudio-standards'
      before_handles = model.getZoneHVACPackagedTerminalAirConditioners.map { |unit| unit.handle.to_s }
      Standard.build(standards_template).model_add_hvac_system(
        model, 'PTAC', 'NaturalGas', nil, 'Electricity', zones
      )
      created = model.getZoneHVACPackagedTerminalAirConditioners.reject do |unit|
        before_handles.include?(unit.handle.to_s)
      end
      created_zones = created.filter_map { |unit| unit.thermalZone.get if unit.thermalZone.is_initialized }
      missing_zones = zones - created_zones
      unless missing_zones.empty?
        runner.registerError("PTAC creation did not produce equipment for: #{missing_zones.map { |zone| zone.name.to_s }.join(', ')}")
        return false
      end

      runner.registerFinalCondition("Created #{created.size} PTAC units for #{zones.size} zones using #{standards_template}.")
      true
    rescue LoadError => e
      runner.registerError("openstudio-standards is unavailable: #{e.message}")
      false
    rescue StandardError => e
      runner.registerError("PTAC creation failed: #{e.message}")
      false
    end
  end
end

CreatePtacHvac.new.registerWithApplication
