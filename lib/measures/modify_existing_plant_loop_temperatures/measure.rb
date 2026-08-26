class ModifyExistingPlantLoopTemperatures < OpenStudio::Measure::ModelMeasure
  def name
    'Modify Existing Plant Loop Temperatures'
  end

  def description
    'Sets the design loop exit temperature on explicitly named plant loops.'
  end

  def modeler_description
    'Performs exact-name matching only and does not infer loop purpose from its name or connected system type.'
  end

  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    names = OpenStudio::Measure::OSArgument.makeStringArgument('target_plant_loop_names', true)
    names.setDisplayName('Target Plant Loop Names')
    names.setDescription('Comma-separated exact OpenStudio plant-loop names.')
    args << names

    temperature = OpenStudio::Measure::OSArgument.makeDoubleArgument('design_loop_exit_temperature_c', true)
    temperature.setDisplayName('Design Loop Exit Temperature (C)')
    temperature.setDefaultValue(15.6)
    args << temperature

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    names = runner.getStringArgumentValue('target_plant_loop_names', user_arguments)
                  .split(',').map(&:strip).reject(&:empty?).uniq
    if names.empty?
      runner.registerError('At least one target_plant_loop_names value is required.')
      return false
    end
    temperature = runner.getDoubleArgumentValue('design_loop_exit_temperature_c', user_arguments)
    loops = model.getPlantLoops.select { |plant_loop| names.include?(plant_loop.name.to_s) }
    missing = names - loops.map { |plant_loop| plant_loop.name.to_s }
    unless missing.empty?
      runner.registerError("Plant loops not found: #{missing.join(', ')}")
      return false
    end

    loops.each do |plant_loop|
      plant_loop.sizingPlant.setDesignLoopExitTemperature(temperature)
      runner.registerInfo("Set design loop exit temperature to #{temperature} C on '#{plant_loop.name}'.")
    end
    runner.registerFinalCondition("Updated design temperature on #{loops.size} explicitly named plant loops.")
    true
  end
end

ModifyExistingPlantLoopTemperatures.new.registerWithApplication
