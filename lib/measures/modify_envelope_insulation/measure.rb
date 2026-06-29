class ModifyEnvelopeInsulation < OpenStudio::Measure::ModelMeasure
  def name
    return "Set Envelope Construction R-Values and U-Values"
  end

  def description
    return "Sets target R-values (or U-values) for exterior walls, roofs, and floors by modifying insulation material thickness in construction assemblies. Accepts either R-value targets or U-value targets, which are automatically converted (R = 1/U)."
  end

  def modeler_description
    return "Modifies construction layer insulation thickness to achieve target overall R-values for exterior opaque surfaces. Supports both R-value and U-value inputs. When U-values are provided, they are converted to R-values. Operates on StandardOpaqueMaterial layers within exterior wall, roof, and floor constructions."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    wall_target_rvalue = OpenStudio::Measure::OSArgument.makeDoubleArgument("wall_target_rvalue", false)
    wall_target_rvalue.setDisplayName("Exterior Wall Target R-value")
    wall_target_rvalue.setDescription("Target overall R-value for exterior walls (m²K/W). Leave 0 to skip walls.")
    wall_target_rvalue.setDefaultValue(0.0)
    args << wall_target_rvalue
    wall_target_uvalue = OpenStudio::Measure::OSArgument.makeDoubleArgument("wall_target_uvalue", false)
    wall_target_uvalue.setDisplayName("Exterior Wall Target U-value (Alternative)")
    wall_target_uvalue.setDescription("Target overall U-value for exterior walls (W/m²K). Automatically converted to R-value (R = 1/U). Leave 0 to use R-value target instead.")
    wall_target_uvalue.setDefaultValue(0.0)
    args << wall_target_uvalue
    roof_target_rvalue = OpenStudio::Measure::OSArgument.makeDoubleArgument("roof_target_rvalue", false)
    roof_target_rvalue.setDisplayName("Roof/Ceiling Target R-value")
    roof_target_rvalue.setDescription("Target overall R-value for roofs and ceilings (m²K/W). Leave 0 to skip roofs.")
    roof_target_rvalue.setDefaultValue(0.0)
    args << roof_target_rvalue
    roof_target_uvalue = OpenStudio::Measure::OSArgument.makeDoubleArgument("roof_target_uvalue", false)
    roof_target_uvalue.setDisplayName("Roof/Ceiling Target U-value (Alternative)")
    roof_target_uvalue.setDescription("Target overall U-value for roofs and ceilings (W/m²K). Automatically converted to R-value (R = 1/U). Leave 0 to use R-value target instead.")
    roof_target_uvalue.setDefaultValue(0.0)
    args << roof_target_uvalue
    floor_target_rvalue = OpenStudio::Measure::OSArgument.makeDoubleArgument("floor_target_rvalue", false)
    floor_target_rvalue.setDisplayName("Floor/Foundation Target R-value")
    floor_target_rvalue.setDescription("Target overall R-value for floors and foundations (m²K/W). Leave 0 to skip floors.")
    floor_target_rvalue.setDefaultValue(0.0)
    args << floor_target_rvalue
    floor_target_uvalue = OpenStudio::Measure::OSArgument.makeDoubleArgument("floor_target_uvalue", false)
    floor_target_uvalue.setDisplayName("Floor/Foundation Target U-value (Alternative)")
    floor_target_uvalue.setDescription("Target overall U-value for floors and foundations (W/m²K). Automatically converted to R-value (R = 1/U). Leave 0 to use R-value target instead.")
    floor_target_uvalue.setDefaultValue(0.0)
    args << floor_target_uvalue
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    wall_target_rvalue = runner.getDoubleArgumentValue("wall_target_rvalue", user_arguments)
    roof_target_rvalue = runner.getDoubleArgumentValue("roof_target_rvalue", user_arguments)
    floor_target_rvalue = runner.getDoubleArgumentValue("floor_target_rvalue", user_arguments)
    wall_target_uvalue = runner.getDoubleArgumentValue("wall_target_uvalue", user_arguments)
    roof_target_uvalue = runner.getDoubleArgumentValue("roof_target_uvalue", user_arguments)
    floor_target_uvalue = runner.getDoubleArgumentValue("floor_target_uvalue", user_arguments)
    # --- begin user logic ---
    # Utility: find and modify insulation material in construction
    add_insulation_layer = lambda do |construction, target_rvalue, surface_type|
      # Cast to proper Construction type
      opt_const = construction.to_Construction
      unless opt_const.is_initialized
        runner.registerWarning("Construction '#{construction.name}' is not a standard Construction, skipping.")
        next false
      end
      construction_obj = opt_const.get

      mat_layers = construction_obj.layers
      if mat_layers.empty?
        runner.registerWarning("Construction '#{construction.name}' has no layers, skipping.")
        next false
      end

      # Calculate current R-value of the construction (all layers, all material types)
      current_rvalue = 0
      mat_layers.each do |mat|
        if mat.to_StandardOpaqueMaterial.is_initialized
          std_mat = mat.to_StandardOpaqueMaterial.get
          if std_mat.thermalConductivity > 0
            current_rvalue += std_mat.thickness / std_mat.thermalConductivity
          end
        elsif mat.to_MasslessOpaqueMaterial.is_initialized
          mml = mat.to_MasslessOpaqueMaterial.get
          # thermalResistance is the R-value for massless materials
          current_rvalue += mml.thermalResistance
        elsif mat.to_AirGap.is_initialized
          current_rvalue += mat.to_AirGap.get.thermalResistance
        end
      end

      runner.registerInfo("#{surface_type}: '#{construction.name}' current R-value = #{current_rvalue.round(4)} m²K/W, target = #{target_rvalue} m²K/W")

      # Skip if target is already met
      if target_rvalue <= current_rvalue
        runner.registerInfo("  -> Already meets target R-value (#{current_rvalue.round(3)} >= #{target_rvalue}), skipping.")
        next false
      end

      # Find the best insulation material to modify (lowest conductivity among Standard materials)
      insulation_mat = nil
      best_conductivity = 999

      mat_layers.each do |mat|
        if mat.to_StandardOpaqueMaterial.is_initialized
          std_mat = mat.to_StandardOpaqueMaterial.get
          if std_mat.thermalConductivity > 0 && std_mat.thermalConductivity < best_conductivity
            insulation_mat = std_mat
            best_conductivity = std_mat.thermalConductivity
          end
        end
      end

      # Fallback: try massless materials
      if insulation_mat.nil?
        mat_layers.each do |mat|
          if mat.to_MasslessOpaqueMaterial.is_initialized
            insulation_mat = mat.to_MasslessOpaqueMaterial.get
            break
          end
        end
      end

      unless insulation_mat
        runner.registerWarning("Could not find modifiable insulation layer in construction '#{construction.name}', skipping.")
        next false
      end

      # Calculate how much additional R-value is needed
      additional_r_needed = target_rvalue - current_rvalue

      if insulation_mat.to_StandardOpaqueMaterial.is_initialized
        insul = insulation_mat.to_StandardOpaqueMaterial.get
        insul_k = insul.thermalConductivity
        current_insul_r = insul.thickness / insul_k
        new_insul_thickness = (current_insul_r + additional_r_needed) * insul_k
        old_thickness = insul.thickness
        insul.setThickness(new_insul_thickness)
        runner.registerInfo("  -> Updated insulation '#{insul.name}': thickness #{old_thickness.round(4)}m → #{new_insul_thickness.round(4)}m (added #{(additional_r_needed).round(3)} m²K/W)")
        next true
      elsif insulation_mat.to_MasslessOpaqueMaterial.is_initialized
        mml = insulation_mat.to_MasslessOpaqueMaterial.get
        new_r = mml.thermalResistance + additional_r_needed
        old_r = mml.thermalResistance
        mml.setThermalResistance(new_r)
        runner.registerInfo("  -> Updated massless insulation '#{mml.name}': R #{old_r.round(3)} → #{new_r.round(3)} m²K/W")
        next true
      end

      false
    end

    # Validate raw inputs
    if [wall_target_rvalue, roof_target_rvalue, floor_target_rvalue, wall_target_uvalue, roof_target_uvalue, floor_target_uvalue].any? { |v| v < 0 }
      runner.registerError('R-value and U-value inputs must be >= 0. Use 0 to skip a surface type.')
      return false
    end

    # Resolve target with explicit priority: R-value first, then U-value if R is 0.
    resolve_target_rvalue = lambda do |label, target_r, target_u|
      if target_r > 0 && target_u > 0
        runner.registerWarning("#{label}: both R-value and U-value were provided. Using R-value and ignoring U-value.")
      end

      next target_r if target_r > 0
      next (1.0 / target_u) if target_u > 0

      0.0
    end

    wall_rvalue = resolve_target_rvalue.call('Wall', wall_target_rvalue, wall_target_uvalue)
    roof_rvalue = resolve_target_rvalue.call('Roof', roof_target_rvalue, roof_target_uvalue)
    floor_rvalue = resolve_target_rvalue.call('Floor', floor_target_rvalue, floor_target_uvalue)

    # Validate inputs
    if [wall_rvalue, roof_rvalue, floor_rvalue].all? { |v| v == 0 }
      runner.registerAsNotApplicable('No target R-values or U-values specified.')
      return true
    end

    unless model.is_a?(OpenStudio::Model::Model)
      runner.registerError('No model found.')
      return false
    end

    # Collect unique constructions by surface type
    wall_constructions = {}
    roof_constructions = {}
    floor_constructions = {}

    model.getSurfaces.each do |surface|
      next unless surface.outsideBoundaryCondition == 'Outdoors'

      surface_type = surface.surfaceType

      opt_construction = surface.construction
      next unless opt_construction.is_initialized
      construction = opt_construction.get
      handle = construction.handle.to_s

      if surface_type == 'Wall'
        wall_constructions[handle] = construction
      elsif surface_type == 'RoofCeiling'
        roof_constructions[handle] = construction
      elsif surface_type == 'Floor'
        floor_constructions[handle] = construction
      end
    end

    # Apply modifications
    changes_made = 0

    wall_constructions.each_value do |construction|
      if wall_rvalue > 0 && add_insulation_layer.call(construction, wall_rvalue, 'Wall')
        changes_made += 1
      end
    end

    roof_constructions.each_value do |construction|
      if roof_rvalue > 0 && add_insulation_layer.call(construction, roof_rvalue, 'Roof')
        changes_made += 1
      end
    end

    floor_constructions.each_value do |construction|
      if floor_rvalue > 0 && add_insulation_layer.call(construction, floor_rvalue, 'Floor')
        changes_made += 1
      end
    end

    if changes_made > 0
      runner.registerInitialCondition("Found #{wall_constructions.size} wall, #{roof_constructions.size} roof, and #{floor_constructions.size} floor constructions.")
      runner.registerFinalCondition("Successfully modified #{changes_made} constructions to adjust insulation.")
    else
      runner.registerAsNotApplicable('No constructions were modified (all already meet target R-values or no modifiable layers found).')
      return true
    end

    return true
# --- end user logic ---
  end
end

ModifyEnvelopeInsulation.new.registerWithApplication
