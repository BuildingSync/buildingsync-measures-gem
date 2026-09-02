class ModifyExistingPlantEquipment < OpenStudio::Measure::ModelMeasure
  PROPERTIES = %w[boiler_capacity_kw boiler_thermal_efficiency chiller_capacity_tons chiller_reference_cop].freeze
  TON_TO_WATT = 3516.85284

  def name
    'Modify Existing Plant Equipment'
  end

  def description
    'Sets one capacity or efficiency property on explicitly named boilers or chillers.'
  end

  def modeler_description
    'Performs exact-name matching and changes only named BoilerHotWater or ChillerElectricEIR objects.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_plant_equipment_names', true)
    names.setDisplayName('Target Plant Equipment Names')
    names.setDescription('Comma-separated exact OpenStudio boiler or chiller names.')
    args << names

    properties = OpenStudio::StringVector.new
    PROPERTIES.each { |property| properties << property }
    property = OpenStudio::Measure::OSArgument.makeChoiceArgument('property', properties, true)
    property.setDisplayName('Property')
    property.setDefaultValue('boiler_thermal_efficiency')
    args << property

    value = OpenStudio::Measure::OSArgument.makeDoubleArgument('value', true)
    value.setDisplayName('Value')
    value.setDescription('Capacity or efficiency in the units implied by property.')
    value.setDefaultValue(0.85)
    args << value

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    names = runner.getStringArgumentValue('target_plant_equipment_names', user_arguments)
                  .split(',').map(&:strip).reject(&:empty?).uniq
    property = runner.getStringArgumentValue('property', user_arguments)
    value = runner.getDoubleArgumentValue('value', user_arguments)
    if names.empty? || value <= 0.0
      runner.registerError('At least one exact name and a value greater than zero are required.')
      return false
    end
    if property == 'boiler_thermal_efficiency' && value > 1.0
      runner.registerError('boiler_thermal_efficiency must be in (0, 1].')
      return false
    end

    equipment = (model.getBoilerHotWaters.to_a + model.getChillerElectricEIRs.to_a).select do |item|
      names.include?(item.name.to_s)
    end
    missing = names - equipment.map { |item| item.name.to_s }
    unless missing.empty?
      runner.registerError("Plant equipment not found: #{missing.join(', ')}")
      return false
    end

    updated = 0
    equipment.each do |item|
      changed = case property
                when 'boiler_capacity_kw'
                  if item.to_BoilerHotWater.is_initialized
                    item.to_BoilerHotWater.get.setNominalCapacity(value * 1000.0)
                    true
                  else
                    false
                  end
                when 'boiler_thermal_efficiency'
                  if item.to_BoilerHotWater.is_initialized
                    item.to_BoilerHotWater.get.setNominalThermalEfficiency(value)
                    true
                  else
                    false
                  end
                when 'chiller_capacity_tons'
                  if item.to_ChillerElectricEIR.is_initialized
                    item.to_ChillerElectricEIR.get.setReferenceCapacity(value * TON_TO_WATT)
                    true
                  else
                    false
                  end
                when 'chiller_reference_cop'
                  if item.to_ChillerElectricEIR.is_initialized
                    item.to_ChillerElectricEIR.get.setReferenceCOP(value)
                    true
                  else
                    false
                  end
                end
      if changed == false
        runner.registerWarning("'#{item.name}' does not support #{property}; it was unchanged.")
      else
        updated += 1
        runner.registerInfo("Set #{property}=#{value} on '#{item.name}'.")
      end
    end
    if updated.zero?
      runner.registerError("None of the named equipment supports #{property}.")
      return false
    end

    runner.registerFinalCondition("Updated #{property} on #{updated} explicitly named plant objects.")
    true
  end
end

ModifyExistingPlantEquipment.new.registerWithApplication
