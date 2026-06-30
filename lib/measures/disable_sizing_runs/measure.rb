class DisableSizingRuns < OpenStudio::Measure::ModelMeasure
  def name
    return "Disable Sizing Runs"
  end

  def description
    return "Disable design sizing-period simulation to allow weather-run-only simulation when no design days are present."
  end

  def modeler_description
    return "Disable design sizing-period simulation to allow weather-run-only simulation when no design days are present."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    # --- begin user logic ---
    sim_control = model.getSimulationControl
    sim_control.setRunSimulationforSizingPeriods(false)
    sim_control.setRunSimulationforWeatherFileRunPeriods(true)
    if sim_control.respond_to?(:setDoZoneSizingCalculation)
      sim_control.setDoZoneSizingCalculation(false)
    end
    if sim_control.respond_to?(:setDoSystemSizingCalculation)
      sim_control.setDoSystemSizingCalculation(false)
    end
    if sim_control.respond_to?(:setDoPlantSizingCalculation)
      sim_control.setDoPlantSizingCalculation(false)
    end
    runner.registerFinalCondition('Disabled sizing-period simulation and kept weather file run period enabled.')
    # --- end user logic ---
    return true
  end
end

DisableSizingRuns.new.registerWithApplication
