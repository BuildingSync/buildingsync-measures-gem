class SetInfiltrationByAch < OpenStudio::Measure::ModelMeasure
  def name
    return "Set Infiltration By Ach"
  end

  def description
    return "Bulk-sets all SpaceInfiltrationDesignFlowRate objects in the model to the AirChanges/Hour calculation method. Accepts either a blower-door ACH50 value (converted to natural ACH using a user-supplied n-factor, default 20) or a natural ACH value directly. All existing infiltration objects are updated in-place; no objects are created or deleted."
  end

  def modeler_description
    return "Iterates getSpaceInfiltrationDesignFlowRates, sets calculation method to AirChanges/Hour, and writes natural_ach. When input_type is ACH50, natural_ach = ach_value / n_factor before writing. Applies registerAsNotApplicable when no infiltration objects exist."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    input_type_choices = OpenStudio::StringVector.new
    input_type_choices << "ACH50"
    input_type_choices << "ACH_natural"
    input_type = OpenStudio::Measure::OSArgument.makeChoiceArgument("input_type", input_type_choices, input_type_choices, true)
    input_type.setDisplayName("Input type")
    input_type.setDescription("Choose ACH50 for blower-door test results at 50 Pa, or ACH_natural for already-converted natural infiltration rate.")
    input_type.setDefaultValue("ACH50")
    args << input_type
    ach_value = OpenStudio::Measure::OSArgument.makeDoubleArgument("ach_value", true)
    ach_value.setDisplayName("ACH value")
    ach_value.setDescription("Numeric ACH value at the stated test pressure (ACH50) or as natural ACH, depending on input_type.")
    ach_value.setDefaultValue(3.0)
    args << ach_value
    n_factor = OpenStudio::Measure::OSArgument.makeDoubleArgument("n_factor", true)
    n_factor.setDisplayName("n-factor (ACH50-to-natural divisor, typically 17–20)")
    n_factor.setDescription("Used only when input_type = ACH50. natural_ACH = ACH50 / n_factor. ASHRAE/LBL default is 20 for commercial.")
    n_factor.setDefaultValue(20.0)
    args << n_factor
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    input_type = runner.getStringArgumentValue("input_type", user_arguments)
    ach_value = runner.getDoubleArgumentValue("ach_value", user_arguments)
    n_factor = runner.getDoubleArgumentValue("n_factor", user_arguments)
    # --- begin user logic ---
    # --- Validate inputs ---
    if ach_value <= 0
      runner.registerError("ACH value must be greater than 0 (got #{ach_value}).")
      return false
    end
    if n_factor <= 0
      runner.registerError("n-factor must be greater than 0 (got #{n_factor}).")
      return false
    end

    # --- Convert ACH50 → natural ACH if needed ---
    if input_type == 'ACH50'
      natural_ach = ach_value / n_factor
      runner.registerInfo("ACH50 #{ach_value} / n-factor #{n_factor} = natural ACH #{natural_ach.round(4)}.")
    else
      natural_ach = ach_value
      runner.registerInfo("Using natural ACH #{natural_ach} directly.")
    end

    # --- Apply to all SpaceInfiltrationDesignFlowRate objects ---
    infil_objects = model.getSpaceInfiltrationDesignFlowRates
    if infil_objects.empty?
      runner.registerAsNotApplicable('No SpaceInfiltrationDesignFlowRate objects found in model.')
      return true
    end

    runner.registerInitialCondition("Model has #{infil_objects.size} infiltration object(s).")

    infil_objects.each do |infil|
      # In OpenStudio 3.x the specific value setter implicitly sets the
      # calculation method; there is no separate setDesignFlowRateCalculationMethod.
      infil.setAirChangesperHour(natural_ach)
    end

    runner.registerFinalCondition("Set #{infil_objects.size} infiltration object(s) to #{natural_ach.round(4)} natural ACH (from #{input_type} = #{ach_value}).")
    # --- end user logic ---
    return true
  end
end

SetInfiltrationByAch.new.registerWithApplication
