class ModifyHvac < OpenStudio::Measure::ModelMeasure
  def name
    return "Modify Hvac"
  end

  def description
    return "L2 HVAC audit translation measure. Modifies or synthesizes HVAC across all 18 BuildingSync PrincipalHVACSystemType enums plus a radiant extension (19 types). Applies audit efficiencies/COPs, supply air temps, economizer controls, ERV effectiveness, and metadata. Synthesizes missing systems via openstudio-standards."
  end

  def modeler_description
    return "Per-type dispatcher covering BuildingSync PrincipalHVACSystemType values. Plant-level args apply globally; zone-equipment args scoped by target_zone_names."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    hvac_system_type_choices = OpenStudio::StringVector.new
    hvac_system_type_choices << "packaged_terminal_air_conditioner"
    hvac_system_type_choices << "packaged_terminal_heat_pump"
    hvac_system_type_choices << "four_pipe_fan_coil_unit"
    hvac_system_type_choices << "packaged_rooftop_air_conditioner"
    hvac_system_type_choices << "packaged_rooftop_heat_pump"
    hvac_system_type_choices << "packaged_rooftop_vav_hot_water_reheat"
    hvac_system_type_choices << "packaged_rooftop_vav_electric_reheat"
    hvac_system_type_choices << "vav_with_hot_water_reheat"
    hvac_system_type_choices << "vav_with_electric_reheat"
    hvac_system_type_choices << "warm_air_furnace"
    hvac_system_type_choices << "ventilation_only"
    hvac_system_type_choices << "dedicated_outdoor_air_system"
    hvac_system_type_choices << "water_loop_heat_pump"
    hvac_system_type_choices << "ground_source_heat_pump"
    hvac_system_type_choices << "vrf_terminal_unit"
    hvac_system_type_choices << "chilled_beam"
    hvac_system_type_choices << "radiant_system"
    hvac_system_type_choices << "other"
    hvac_system_type_choices << "unknown"
    hvac_system_type_choices << "existing_unknown_mixed_system"
    hvac_system_type_choices << "vav_with_boiler_and_central_chiller"
    hvac_system_type_choices << "fan_coil_with_central_plant"
    hvac_system_type = OpenStudio::Measure::OSArgument.makeChoiceArgument("hvac_system_type", hvac_system_type_choices, hvac_system_type_choices, true)
    hvac_system_type.setDisplayName("HVAC System Type")
    hvac_system_type.setDescription("BuildingSync PrincipalHVACSystemType (snake_cased) + radiant extension. 'other', 'unknown', 'existing_unknown_mixed_system' leave HVAC unchanged.")
    hvac_system_type.setDefaultValue("vav_with_hot_water_reheat")
    args << hvac_system_type
    target_air_loop_name = OpenStudio::Measure::OSArgument.makeStringArgument("target_air_loop_name", false)
    target_air_loop_name.setDisplayName("Target Air Loop Name")
    target_air_loop_name.setDescription("Exact air loop name. Blank = all.")
    target_air_loop_name.setDefaultValue("")
    args << target_air_loop_name
    target_zone_names = OpenStudio::Measure::OSArgument.makeStringArgument("target_zone_names", false)
    target_zone_names.setDisplayName("Target Zone Names")
    target_zone_names.setDescription("Comma-separated thermal zone names for zone-equipment scoping. Blank = all. Plant-level args still apply globally.")
    target_zone_names.setDefaultValue("")
    args << target_zone_names
    synthesize_if_missing = OpenStudio::Measure::OSArgument.makeBoolArgument("synthesize_if_missing", true)
    synthesize_if_missing.setDisplayName("Synthesize Missing Equipment")
    synthesize_if_missing.setDescription("If true, use openstudio-standards to add the system when absent, then tune.")
    synthesize_if_missing.setDefaultValue(true)
    args << synthesize_if_missing
    economizer_control_type_choices = OpenStudio::StringVector.new
    economizer_control_type_choices << "NoEconomizer"
    economizer_control_type_choices << "FixedDryBulb"
    economizer_control_type_choices << "FixedEnthalpy"
    economizer_control_type_choices << "DifferentialDryBulb"
    economizer_control_type_choices << "DifferentialEnthalpy"
    economizer_control_type_choices << "ElectronicEnthalpy"
    economizer_control_type = OpenStudio::Measure::OSArgument.makeChoiceArgument("economizer_control_type", economizer_control_type_choices, economizer_control_type_choices, true)
    economizer_control_type.setDisplayName("Economizer Control Type")
    economizer_control_type.setDescription("OA economizer strategy (air-loop types only).")
    economizer_control_type.setDefaultValue("FixedDryBulb")
    args << economizer_control_type
    economizer_high_limit_dry_bulb_temperature_c = OpenStudio::Measure::OSArgument.makeDoubleArgument("economizer_high_limit_dry_bulb_temperature_c", true)
    economizer_high_limit_dry_bulb_temperature_c.setDisplayName("Econ High Limit DB (C)")
    economizer_high_limit_dry_bulb_temperature_c.setDescription("Dry-bulb lockout (C).")
    economizer_high_limit_dry_bulb_temperature_c.setDefaultValue(24.0)
    args << economizer_high_limit_dry_bulb_temperature_c
    economizer_high_limit_enthalpy_j_kg = OpenStudio::Measure::OSArgument.makeDoubleArgument("economizer_high_limit_enthalpy_j_kg", true)
    economizer_high_limit_enthalpy_j_kg.setDisplayName("Econ High Limit Enthalpy (J/kg)")
    economizer_high_limit_enthalpy_j_kg.setDescription("Enthalpy lockout (J/kg).")
    economizer_high_limit_enthalpy_j_kg.setDefaultValue(64000.0)
    args << economizer_high_limit_enthalpy_j_kg
    central_cooling_supply_air_temperature_c = OpenStudio::Measure::OSArgument.makeDoubleArgument("central_cooling_supply_air_temperature_c", true)
    central_cooling_supply_air_temperature_c.setDisplayName("Central Cooling SAT (C)")
    central_cooling_supply_air_temperature_c.setDescription("Air-loop cooling design SAT.")
    central_cooling_supply_air_temperature_c.setDefaultValue(12.8)
    args << central_cooling_supply_air_temperature_c
    central_heating_supply_air_temperature_c = OpenStudio::Measure::OSArgument.makeDoubleArgument("central_heating_supply_air_temperature_c", true)
    central_heating_supply_air_temperature_c.setDisplayName("Central Heating SAT (C)")
    central_heating_supply_air_temperature_c.setDescription("Air-loop heating design SAT.")
    central_heating_supply_air_temperature_c.setDefaultValue(32.0)
    args << central_heating_supply_air_temperature_c
    doas_supply_air_temperature_c = OpenStudio::Measure::OSArgument.makeDoubleArgument("doas_supply_air_temperature_c", true)
    doas_supply_air_temperature_c.setDisplayName("DOAS SAT (C)")
    doas_supply_air_temperature_c.setDescription("DOAS neutral-air supply temp (C). Used by DOAS / ventilation_only / chilled_beam.")
    doas_supply_air_temperature_c.setDefaultValue(18.3)
    args << doas_supply_air_temperature_c
    erv_sensible_effectiveness = OpenStudio::Measure::OSArgument.makeDoubleArgument("erv_sensible_effectiveness", true)
    erv_sensible_effectiveness.setDisplayName("ERV Sensible Effectiveness")
    erv_sensible_effectiveness.setDescription("Target sensible effectiveness (0-1). 0 = leave unchanged.")
    erv_sensible_effectiveness.setDefaultValue(0.0)
    args << erv_sensible_effectiveness
    erv_latent_effectiveness = OpenStudio::Measure::OSArgument.makeDoubleArgument("erv_latent_effectiveness", true)
    erv_latent_effectiveness.setDisplayName("ERV Latent Effectiveness")
    erv_latent_effectiveness.setDescription("Target latent effectiveness (0-1). 0 = leave unchanged.")
    erv_latent_effectiveness.setDefaultValue(0.0)
    args << erv_latent_effectiveness
    design_heating_capacity_kw = OpenStudio::Measure::OSArgument.makeDoubleArgument("design_heating_capacity_kw", true)
    design_heating_capacity_kw.setDisplayName("Design Heating Capacity (kW)")
    design_heating_capacity_kw.setDescription("Fallback for boiler capacity.")
    design_heating_capacity_kw.setDefaultValue(0.0)
    args << design_heating_capacity_kw
    design_cooling_capacity_tons = OpenStudio::Measure::OSArgument.makeDoubleArgument("design_cooling_capacity_tons", true)
    design_cooling_capacity_tons.setDisplayName("Design Cooling Capacity (tons)")
    design_cooling_capacity_tons.setDescription("Fallback for chiller capacity.")
    design_cooling_capacity_tons.setDefaultValue(0.0)
    args << design_cooling_capacity_tons
    boiler_capacity_kw = OpenStudio::Measure::OSArgument.makeDoubleArgument("boiler_capacity_kw", true)
    boiler_capacity_kw.setDisplayName("Boiler Capacity (kW)")
    boiler_capacity_kw.setDescription("0 = autosize preserved.")
    boiler_capacity_kw.setDefaultValue(0.0)
    args << boiler_capacity_kw
    boiler_nominal_thermal_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument("boiler_nominal_thermal_efficiency", true)
    boiler_nominal_thermal_efficiency.setDisplayName("Boiler Efficiency")
    boiler_nominal_thermal_efficiency.setDescription("BoilerHotWater nominal thermal efficiency (0-1).")
    boiler_nominal_thermal_efficiency.setDefaultValue(0.85)
    args << boiler_nominal_thermal_efficiency
    chiller_capacity_tons = OpenStudio::Measure::OSArgument.makeDoubleArgument("chiller_capacity_tons", true)
    chiller_capacity_tons.setDisplayName("Chiller Capacity (tons)")
    chiller_capacity_tons.setDescription("0 = autosize preserved.")
    chiller_capacity_tons.setDefaultValue(0.0)
    args << chiller_capacity_tons
    chiller_reference_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument("chiller_reference_cop", true)
    chiller_reference_cop.setDisplayName("Chiller COP")
    chiller_reference_cop.setDescription("ChillerElectricEIR reference COP (>0).")
    chiller_reference_cop.setDefaultValue(5.5)
    args << chiller_reference_cop
    dx_cooling_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument("dx_cooling_cop", true)
    dx_cooling_cop.setDisplayName("DX Cooling COP")
    dx_cooling_cop.setDescription("CoilCoolingDX rated COP. Used by PTAC / PSZ-AC / Pkg RTU VAV (both).")
    dx_cooling_cop.setDefaultValue(3.5)
    args << dx_cooling_cop
    gas_furnace_thermal_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument("gas_furnace_thermal_efficiency", true)
    gas_furnace_thermal_efficiency.setDisplayName("Gas Furnace Efficiency")
    gas_furnace_thermal_efficiency.setDescription("CoilHeatingGas burner efficiency (0-1).")
    gas_furnace_thermal_efficiency.setDefaultValue(0.8)
    args << gas_furnace_thermal_efficiency
    heat_pump_cooling_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument("heat_pump_cooling_cop", true)
    heat_pump_cooling_cop.setDisplayName("HP Cooling COP")
    heat_pump_cooling_cop.setDescription("DX HP / VRF / WSHP rated cooling COP.")
    heat_pump_cooling_cop.setDefaultValue(3.5)
    args << heat_pump_cooling_cop
    heat_pump_heating_cop = OpenStudio::Measure::OSArgument.makeDoubleArgument("heat_pump_heating_cop", true)
    heat_pump_heating_cop.setDisplayName("HP Heating COP")
    heat_pump_heating_cop.setDescription("DX HP / VRF / WSHP rated heating COP.")
    heat_pump_heating_cop.setDefaultValue(3.2)
    args << heat_pump_heating_cop
    backup_resistance_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument("backup_resistance_efficiency", true)
    backup_resistance_efficiency.setDisplayName("Backup Resistance Efficiency")
    backup_resistance_efficiency.setDescription("CoilHeatingElectric efficiency (0-1).")
    backup_resistance_efficiency.setDefaultValue(1.0)
    args << backup_resistance_efficiency
    radiant_chilled_water_supply_temperature_c = OpenStudio::Measure::OSArgument.makeDoubleArgument("radiant_chilled_water_supply_temperature_c", true)
    radiant_chilled_water_supply_temperature_c.setDisplayName("Radiant CHW Supply (C)")
    radiant_chilled_water_supply_temperature_c.setDescription("Low-temp radiant CHW supply.")
    radiant_chilled_water_supply_temperature_c.setDefaultValue(15.6)
    args << radiant_chilled_water_supply_temperature_c
    radiant_hot_water_supply_temperature_c = OpenStudio::Measure::OSArgument.makeDoubleArgument("radiant_hot_water_supply_temperature_c", true)
    radiant_hot_water_supply_temperature_c.setDisplayName("Radiant HW Supply (C)")
    radiant_hot_water_supply_temperature_c.setDescription("Low-temp radiant HW supply.")
    radiant_hot_water_supply_temperature_c.setDefaultValue(43.3)
    args << radiant_hot_water_supply_temperature_c
    chilled_beam_primary_air_fraction = OpenStudio::Measure::OSArgument.makeDoubleArgument("chilled_beam_primary_air_fraction", true)
    chilled_beam_primary_air_fraction.setDisplayName("Chilled Beam Primary Air Fraction")
    chilled_beam_primary_air_fraction.setDescription("Metadata only.")
    chilled_beam_primary_air_fraction.setDefaultValue(0.3)
    args << chilled_beam_primary_air_fraction
    year_installed = OpenStudio::Measure::OSArgument.makeIntegerArgument("year_installed", true)
    year_installed.setDisplayName("Year Installed")
    year_installed.setDescription("Audit metadata (1950-2100).")
    year_installed.setDefaultValue(2015)
    args << year_installed
    condition_assessment_choices = OpenStudio::StringVector.new
    condition_assessment_choices << "excellent"
    condition_assessment_choices << "good"
    condition_assessment_choices << "average"
    condition_assessment_choices << "poor"
    condition_assessment_choices << "unknown"
    condition_assessment = OpenStudio::Measure::OSArgument.makeChoiceArgument("condition_assessment", condition_assessment_choices, condition_assessment_choices, true)
    condition_assessment.setDisplayName("Condition Assessment")
    condition_assessment.setDescription("Audit metadata.")
    condition_assessment.setDefaultValue("average")
    args << condition_assessment
    control_type_audit_choices = OpenStudio::StringVector.new
    control_type_audit_choices << "pneumatic"
    control_type_audit_choices << "direct_digital_control"
    control_type_audit_choices << "unknown"
    control_type_audit = OpenStudio::Measure::OSArgument.makeChoiceArgument("control_type_audit", control_type_audit_choices, control_type_audit_choices, true)
    control_type_audit.setDisplayName("Control Type (Audit)")
    control_type_audit.setDescription("Audit metadata.")
    control_type_audit.setDefaultValue("direct_digital_control")
    args << control_type_audit
    zone_control_strategy_choices = OpenStudio::StringVector.new
    zone_control_strategy_choices << "core_perimeter"
    zone_control_strategy_choices << "all_zones"
    zone_control_strategy_choices << "space_types"
    zone_control_strategy = OpenStudio::Measure::OSArgument.makeChoiceArgument("zone_control_strategy", zone_control_strategy_choices, zone_control_strategy_choices, true)
    zone_control_strategy.setDisplayName("Zone Control Strategy")
    zone_control_strategy.setDescription("Audit metadata.")
    zone_control_strategy.setDefaultValue("core_perimeter")
    args << zone_control_strategy
    preserve_existing_sizing = OpenStudio::Measure::OSArgument.makeBoolArgument("preserve_existing_sizing", true)
    preserve_existing_sizing.setDisplayName("Preserve Existing Sizing")
    preserve_existing_sizing.setDescription("If true, keep autosized capacities; only apply efficiencies/COPs.")
    preserve_existing_sizing.setDefaultValue(false)
    args << preserve_existing_sizing
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    hvac_system_type = runner.getStringArgumentValue("hvac_system_type", user_arguments)
    target_air_loop_name = runner.getStringArgumentValue("target_air_loop_name", user_arguments)
    target_zone_names = runner.getStringArgumentValue("target_zone_names", user_arguments)
    synthesize_if_missing = runner.getBoolArgumentValue("synthesize_if_missing", user_arguments)
    economizer_control_type = runner.getStringArgumentValue("economizer_control_type", user_arguments)
    economizer_high_limit_dry_bulb_temperature_c = runner.getDoubleArgumentValue("economizer_high_limit_dry_bulb_temperature_c", user_arguments)
    economizer_high_limit_enthalpy_j_kg = runner.getDoubleArgumentValue("economizer_high_limit_enthalpy_j_kg", user_arguments)
    central_cooling_supply_air_temperature_c = runner.getDoubleArgumentValue("central_cooling_supply_air_temperature_c", user_arguments)
    central_heating_supply_air_temperature_c = runner.getDoubleArgumentValue("central_heating_supply_air_temperature_c", user_arguments)
    doas_supply_air_temperature_c = runner.getDoubleArgumentValue("doas_supply_air_temperature_c", user_arguments)
    erv_sensible_effectiveness = runner.getDoubleArgumentValue("erv_sensible_effectiveness", user_arguments)
    erv_latent_effectiveness = runner.getDoubleArgumentValue("erv_latent_effectiveness", user_arguments)
    design_heating_capacity_kw = runner.getDoubleArgumentValue("design_heating_capacity_kw", user_arguments)
    design_cooling_capacity_tons = runner.getDoubleArgumentValue("design_cooling_capacity_tons", user_arguments)
    boiler_capacity_kw = runner.getDoubleArgumentValue("boiler_capacity_kw", user_arguments)
    boiler_nominal_thermal_efficiency = runner.getDoubleArgumentValue("boiler_nominal_thermal_efficiency", user_arguments)
    chiller_capacity_tons = runner.getDoubleArgumentValue("chiller_capacity_tons", user_arguments)
    chiller_reference_cop = runner.getDoubleArgumentValue("chiller_reference_cop", user_arguments)
    dx_cooling_cop = runner.getDoubleArgumentValue("dx_cooling_cop", user_arguments)
    gas_furnace_thermal_efficiency = runner.getDoubleArgumentValue("gas_furnace_thermal_efficiency", user_arguments)
    heat_pump_cooling_cop = runner.getDoubleArgumentValue("heat_pump_cooling_cop", user_arguments)
    heat_pump_heating_cop = runner.getDoubleArgumentValue("heat_pump_heating_cop", user_arguments)
    backup_resistance_efficiency = runner.getDoubleArgumentValue("backup_resistance_efficiency", user_arguments)
    radiant_chilled_water_supply_temperature_c = runner.getDoubleArgumentValue("radiant_chilled_water_supply_temperature_c", user_arguments)
    radiant_hot_water_supply_temperature_c = runner.getDoubleArgumentValue("radiant_hot_water_supply_temperature_c", user_arguments)
    chilled_beam_primary_air_fraction = runner.getDoubleArgumentValue("chilled_beam_primary_air_fraction", user_arguments)
    year_installed = runner.getIntegerArgumentValue("year_installed", user_arguments)
    condition_assessment = runner.getStringArgumentValue("condition_assessment", user_arguments)
    control_type_audit = runner.getStringArgumentValue("control_type_audit", user_arguments)
    zone_control_strategy = runner.getStringArgumentValue("zone_control_strategy", user_arguments)
    preserve_existing_sizing = runner.getBoolArgumentValue("preserve_existing_sizing", user_arguments)
    # --- begin user logic ---
    runner.registerInitialCondition("Start: #{model.getAirLoopHVACs.size} loops, #{model.getPlantLoops.size} plants, #{model.getThermalZones.size} zones, #{model.getBoilerHotWaters.size} boilers, #{model.getChillerElectricEIRs.size} chillers.")
    if boiler_nominal_thermal_efficiency <= 0.0 || boiler_nominal_thermal_efficiency > 1.0
      runner.registerError('boiler_nominal_thermal_efficiency must be in (0,1].'); return false
    end
    if gas_furnace_thermal_efficiency <= 0.0 || gas_furnace_thermal_efficiency > 1.0
      runner.registerError('gas_furnace_thermal_efficiency must be in (0,1].'); return false
    end
    if backup_resistance_efficiency <= 0.0 || backup_resistance_efficiency > 1.0
      runner.registerError('backup_resistance_efficiency must be in (0,1].'); return false
    end
    [chiller_reference_cop, dx_cooling_cop, heat_pump_cooling_cop, heat_pump_heating_cop].each do |c|
      if c <= 0.0
        runner.registerError('COPs must be > 0.'); return false
      end
    end
    if erv_sensible_effectiveness < 0 || erv_sensible_effectiveness > 1 || erv_latent_effectiveness < 0 || erv_latent_effectiveness > 1
      runner.registerError('ERV effectiveness must be in [0,1].'); return false
    end
    if year_installed < 1950 || year_installed > 2100
      runner.registerError('year_installed must be 1950-2100.'); return false
    end
    if design_heating_capacity_kw < 0 || design_cooling_capacity_tons < 0 || boiler_capacity_kw < 0 || chiller_capacity_tons < 0
      runner.registerError('Capacities must be non-negative.'); return false
    end
    hvac_system_type = 'vav_with_hot_water_reheat' if hvac_system_type == 'vav_with_boiler_and_central_chiller'
    hvac_system_type = 'four_pipe_fan_coil_unit' if hvac_system_type == 'fan_coil_with_central_plant'
    hvac_system_type = 'unknown' if hvac_system_type == 'existing_unknown_mixed_system'
    if hvac_system_type == 'other' || hvac_system_type == 'unknown'
      runner.registerAsNotApplicable("Type '#{hvac_system_type}' is metadata-only; unchanged.")
      return true
    end
    zone_names = target_zone_names.to_s.split(',').map(&:strip).reject(&:empty?)
    target_zones = zone_names.empty? ? model.getThermalZones : model.getThermalZones.select { |z| zone_names.include?(z.name.to_s) }
    if target_zones.empty?
      runner.registerError("No zones matched target_zone_names='#{target_zone_names}'."); return false
    end
    tln = target_air_loop_name.to_s.strip
    target_loops = tln.empty? ? model.getAirLoopHVACs : model.getAirLoopHVACs.select { |l| l.name.to_s == tln }
    stds = false
    load_stds = lambda do
      return true if stds
      begin; require 'openstudio-standards'; stds = true; true
      rescue LoadError => e; runner.registerError("openstudio-standards unavailable: #{e.message}"); false; end
    end
    counts = { loops: 0, zeq: 0, coils: 0, erv: 0, b: 0, ch: 0 }
    syn = false
    synth = lambda do |k|
      return false unless synthesize_if_missing && load_stds.call
      begin
        Standard.build('90.1-2019').model_add_hvac_system(model, k, 'NaturalGas', nil, 'Electricity', target_zones.to_a)
        runner.registerInfo("Synthesized '#{k}' for #{target_zones.size} zones.")
        syn = true; true
      rescue => e; runner.registerError("Synth '#{k}' failed: #{e.message}"); false; end
    end
    app_econ = lambda do |al|
      oas = al.airLoopHVACOutdoorAirSystem
      return unless oas.is_initialized
      ctl = oas.get.getControllerOutdoorAir
      ctl.setEconomizerControlType(economizer_control_type)
      if ['FixedDryBulb','DifferentialDryBulb'].include?(economizer_control_type)
        ctl.setEconomizerMaximumLimitDryBulbTemperature(economizer_high_limit_dry_bulb_temperature_c)
      elsif ['FixedEnthalpy','DifferentialEnthalpy','ElectronicEnthalpy'].include?(economizer_control_type)
        ctl.setEconomizerMaximumLimitEnthalpy(economizer_high_limit_enthalpy_j_kg)
      end
    end
    app_sat = lambda do |al, c_sat, h_sat|
      ss = al.sizingSystem
      ss.setCentralCoolingDesignSupplyAirTemperature(c_sat)
      ss.setCentralHeatingDesignSupplyAirTemperature(h_sat)
    end
    upd_plant = lambda do
      model.getBoilerHotWaters.each do |b|
        b.setNominalThermalEfficiency(boiler_nominal_thermal_efficiency)
        cap = boiler_capacity_kw > 0 ? boiler_capacity_kw : design_heating_capacity_kw
        b.setNominalCapacity(cap * 1000.0) if !preserve_existing_sizing && cap > 0
        counts[:b] += 1
      end
      model.getChillerElectricEIRs.each do |c|
        c.setReferenceCOP(chiller_reference_cop)
        cap = chiller_capacity_tons > 0 ? chiller_capacity_tons : design_cooling_capacity_tons
        c.setReferenceCapacity(cap * 3516.85284) if !preserve_existing_sizing && cap > 0
        counts[:ch] += 1
      end
    end
    upd_dx_c = lambda do |c, cop|
      if c.to_CoilCoolingDXSingleSpeed.is_initialized
        c.to_CoilCoolingDXSingleSpeed.get.setRatedCOP(cop); counts[:coils] += 1; true
      elsif c.to_CoilCoolingDXTwoSpeed.is_initialized
        x = c.to_CoilCoolingDXTwoSpeed.get; x.setRatedHighSpeedCOP(cop); x.setRatedLowSpeedCOP(cop); counts[:coils] += 1; true
      else false; end
    end
    upd_dx_h = lambda do |c|
      if c.to_CoilHeatingDXSingleSpeed.is_initialized
        c.to_CoilHeatingDXSingleSpeed.get.setRatedCOP(heat_pump_heating_cop); counts[:coils] += 1; true
      else false; end
    end
    upd_gas = lambda do |c|
      if c.to_CoilHeatingGas.is_initialized
        c.to_CoilHeatingGas.get.setGasBurnerEfficiency(gas_furnace_thermal_efficiency); counts[:coils] += 1; true
      else false; end
    end
    upd_elec = lambda do |c|
      if c.to_CoilHeatingElectric.is_initialized
        c.to_CoilHeatingElectric.get.setEfficiency(backup_resistance_efficiency); counts[:coils] += 1; true
      else false; end
    end
    upd_erv = lambda do |al|
      return unless erv_sensible_effectiveness > 0 || erv_latent_effectiveness > 0
      al.oaComponents.each do |c|
        next unless c.to_HeatExchangerAirToAirSensibleAndLatent.is_initialized
        hx = c.to_HeatExchangerAirToAirSensibleAndLatent.get
        if erv_sensible_effectiveness > 0
          hx.setSensibleEffectivenessat100CoolingAirFlow(erv_sensible_effectiveness)
          hx.setSensibleEffectivenessat75CoolingAirFlow(erv_sensible_effectiveness)
          hx.setSensibleEffectivenessat100HeatingAirFlow(erv_sensible_effectiveness)
          hx.setSensibleEffectivenessat75HeatingAirFlow(erv_sensible_effectiveness)
        end
        if erv_latent_effectiveness > 0
          hx.setLatentEffectivenessat100CoolingAirFlow(erv_latent_effectiveness)
          hx.setLatentEffectivenessat75CoolingAirFlow(erv_latent_effectiveness)
          hx.setLatentEffectivenessat100HeatingAirFlow(erv_latent_effectiveness)
          hx.setLatentEffectivenessat75HeatingAirFlow(erv_latent_effectiveness)
        end
        counts[:erv] += 1
      end
    end
    loops_touch_zones = lambda do |loops|
      loops.select { |l| l.thermalZones.any? { |z| target_zones.include?(z) } }
    end
    # Walk supply components AND unwrap AirLoopHVACUnitarySystem / heat-pump wrappers
    each_supply_coil = lambda do |al, &blk|
      al.supplyComponents.each do |c|
        if c.to_AirLoopHVACUnitarySystem.is_initialized
          us = c.to_AirLoopHVACUnitarySystem.get
          blk.call(us.coolingCoil.get) if us.coolingCoil.is_initialized
          blk.call(us.heatingCoil.get) if us.heatingCoil.is_initialized
          blk.call(us.supplementalHeatingCoil.get) if us.supplementalHeatingCoil.is_initialized
        elsif c.to_AirLoopHVACUnitaryHeatPumpAirToAir.is_initialized
          hp = c.to_AirLoopHVACUnitaryHeatPumpAirToAir.get
          blk.call(hp.coolingCoil)
          blk.call(hp.heatingCoil)
          blk.call(hp.supplementalHeatingCoil)
        else
          blk.call(c)
        end
      end
    end
    case hvac_system_type
    when 'ventilation_only', 'dedicated_outdoor_air_system'
      if target_loops.empty?
        synth.call(hvac_system_type == 'ventilation_only' ? 'Ventilation Only' : 'DOAS') || (return false)
        target_loops = model.getAirLoopHVACs
      end
      target_loops.each do |al|
        app_sat.call(al, doas_supply_air_temperature_c, doas_supply_air_temperature_c)
        app_econ.call(al); upd_erv.call(al); counts[:loops] += 1
      end
    when 'packaged_terminal_air_conditioner'
      list = model.getZoneHVACPackagedTerminalAirConditioners
      if list.empty?; synth.call('PTAC') || (return false); list = model.getZoneHVACPackagedTerminalAirConditioners; end
      list.each do |p|
        tz = p.thermalZone; next if tz.is_initialized && !target_zones.include?(tz.get)
        upd_dx_c.call(p.coolingCoil, dx_cooling_cop)
        upd_elec.call(p.heatingCoil) || upd_gas.call(p.heatingCoil)
        counts[:zeq] += 1
      end
    when 'packaged_terminal_heat_pump'
      list = model.getZoneHVACPackagedTerminalHeatPumps
      if list.empty?; synth.call('PTHP') || (return false); list = model.getZoneHVACPackagedTerminalHeatPumps; end
      list.each do |p|
        tz = p.thermalZone; next if tz.is_initialized && !target_zones.include?(tz.get)
        upd_dx_c.call(p.coolingCoil, heat_pump_cooling_cop)
        upd_dx_h.call(p.heatingCoil)
        upd_elec.call(p.supplementalHeatingCoil)
        counts[:zeq] += 1
      end
    when 'four_pipe_fan_coil_unit'
      list = model.getZoneHVACFourPipeFanCoils
      if list.empty?; synth.call('Fan Coil') || (return false); list = model.getZoneHVACFourPipeFanCoils; end
      list.each do |f|
        tz = f.thermalZone; next if tz.is_initialized && !target_zones.include?(tz.get)
        counts[:zeq] += 1
      end
      upd_plant.call
    when 'packaged_rooftop_air_conditioner', 'packaged_rooftop_heat_pump'
      is_hp = hvac_system_type == 'packaged_rooftop_heat_pump'
      loops = loops_touch_zones.call(target_loops)
      if loops.empty?; synth.call(is_hp ? 'PSZ-HP' : 'PSZ-AC') || (return false); loops = loops_touch_zones.call(model.getAirLoopHVACs); end
      loops.each do |al|
        app_sat.call(al, central_cooling_supply_air_temperature_c, central_heating_supply_air_temperature_c)
        app_econ.call(al); counts[:loops] += 1
        each_supply_coil.call(al) do |c|
          if is_hp
            upd_dx_c.call(c, heat_pump_cooling_cop) || upd_dx_h.call(c) || upd_elec.call(c)
          else
            upd_dx_c.call(c, dx_cooling_cop) || upd_gas.call(c) || upd_elec.call(c)
          end
        end
      end
    when 'packaged_rooftop_vav_hot_water_reheat', 'packaged_rooftop_vav_electric_reheat'
      is_elec = hvac_system_type == 'packaged_rooftop_vav_electric_reheat'
      loops = loops_touch_zones.call(target_loops)
      if loops.empty?; synth.call(is_elec ? 'PVAV PFP Boxes' : 'PVAV Reheat') || (return false); loops = loops_touch_zones.call(model.getAirLoopHVACs); end
      loops.each do |al|
        app_sat.call(al, central_cooling_supply_air_temperature_c, central_heating_supply_air_temperature_c)
        app_econ.call(al); counts[:loops] += 1
        each_supply_coil.call(al) { |c| upd_dx_c.call(c, dx_cooling_cop) || upd_gas.call(c) || upd_elec.call(c) }
        if is_elec
          al.demandComponents.each { |c| upd_elec.call(c) }
        end
      end
      upd_plant.call unless is_elec
    when 'vav_with_hot_water_reheat', 'vav_with_electric_reheat'
      is_elec = hvac_system_type == 'vav_with_electric_reheat'
      loops = loops_touch_zones.call(target_loops)
      if loops.empty?; synth.call(is_elec ? 'VAV PFP Boxes' : 'VAV Reheat') || (return false); loops = loops_touch_zones.call(model.getAirLoopHVACs); end
      loops.each do |al|
        app_sat.call(al, central_cooling_supply_air_temperature_c, central_heating_supply_air_temperature_c)
        app_econ.call(al); counts[:loops] += 1
        al.demandComponents.each { |c| upd_elec.call(c) } if is_elec
      end
      upd_plant.call
    when 'warm_air_furnace'
      uhs = model.getZoneHVACUnitHeaters
      if target_loops.empty? && uhs.empty?
        synth.call('Forced Air Furnace') || (return false)
        target_loops = model.getAirLoopHVACs; uhs = model.getZoneHVACUnitHeaters
      end
      loops_touch_zones.call(target_loops).each do |al|
        app_sat.call(al, central_cooling_supply_air_temperature_c, central_heating_supply_air_temperature_c)
        app_econ.call(al); counts[:loops] += 1
        each_supply_coil.call(al) { |c| upd_gas.call(c) || upd_elec.call(c) || upd_dx_c.call(c, dx_cooling_cop) }
      end
      uhs.each do |u|
        tz = u.thermalZone; next if tz.is_initialized && !target_zones.include?(tz.get)
        upd_gas.call(u.heatingCoil) || upd_elec.call(u.heatingCoil)
        counts[:zeq] += 1
      end
    when 'water_loop_heat_pump', 'ground_source_heat_pump'
      list = model.getZoneHVACWaterToAirHeatPumps
      if list.empty?
        synth.call(hvac_system_type == 'ground_source_heat_pump' ? 'Ground Source Heat Pumps' : 'Water Source Heat Pumps') || (return false)
        list = model.getZoneHVACWaterToAirHeatPumps
      end
      list.each do |w|
        tz = w.thermalZone; next if tz.is_initialized && !target_zones.include?(tz.get)
        cc = w.coolingCoil
        if cc.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
          cc.to_CoilCoolingWaterToAirHeatPumpEquationFit.get.setRatedCoolingCoefficientofPerformance(heat_pump_cooling_cop)
          counts[:coils] += 1
        end
        hc = w.heatingCoil
        if hc.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
          hc.to_CoilHeatingWaterToAirHeatPumpEquationFit.get.setRatedHeatingCoefficientofPerformance(heat_pump_heating_cop)
          counts[:coils] += 1
        end
        upd_elec.call(w.supplementalHeatingCoil)
        counts[:zeq] += 1
      end
      upd_plant.call if hvac_system_type == 'water_loop_heat_pump'
    when 'vrf_terminal_unit'
      list = model.getAirConditionerVariableRefrigerantFlows
      if list.empty?; synth.call('VRF') || (return false); list = model.getAirConditionerVariableRefrigerantFlows; end
      list.each do |v|
        v.setRatedCoolingCOP(heat_pump_cooling_cop); v.setRatedHeatingCOP(heat_pump_heating_cop); counts[:coils] += 1
      end
    when 'chilled_beam'
      if target_loops.empty?; synth.call('DOAS') || (return false); target_loops = model.getAirLoopHVACs; end
      target_loops.each do |al|
        app_sat.call(al, doas_supply_air_temperature_c, doas_supply_air_temperature_c)
        app_econ.call(al); upd_erv.call(al); counts[:loops] += 1
      end
      upd_plant.call
    when 'radiant_system'
      rads = model.getZoneHVACLowTempRadiantVarFlows + model.getZoneHVACLowTempRadiantConstFlows
      if rads.empty?
        synth.call('Radiant Slab') || (return false)
        rads = model.getZoneHVACLowTempRadiantVarFlows + model.getZoneHVACLowTempRadiantConstFlows
      end
      model.getPlantLoops.each do |pl|
        n = pl.name.to_s.downcase
        if n.include?('chilled') || n.include?('cooling')
          pl.sizingPlant.setDesignLoopExitTemperature(radiant_chilled_water_supply_temperature_c)
        elsif n.include?('hot') || n.include?('heating')
          pl.sizingPlant.setDesignLoopExitTemperature(radiant_hot_water_supply_temperature_c)
        end
      end
      rads.each do |r|
        tz = r.thermalZone; next if tz.is_initialized && !target_zones.include?(tz.get)
        counts[:zeq] += 1
      end
      upd_plant.call
    else
      runner.registerError("Unknown hvac_system_type: '#{hvac_system_type}'."); return false
    end
    runner.registerInfo("audit: type=#{hvac_system_type} year=#{year_installed} cond=#{condition_assessment} ctrl=#{control_type_audit} zctl=#{zone_control_strategy} synth=#{syn} boil_eff=#{boiler_nominal_thermal_efficiency} chill_cop=#{chiller_reference_cop} dx_cop=#{dx_cooling_cop} furn=#{gas_furnace_thermal_efficiency} hp_c=#{heat_pump_cooling_cop} hp_h=#{heat_pump_heating_cop} elec=#{backup_resistance_efficiency} preserve=#{preserve_existing_sizing}")
    runner.registerFinalCondition("modify_hvac[#{hvac_system_type}] synth=#{syn} loops=#{counts[:loops]} zeq=#{counts[:zeq]} coils=#{counts[:coils]} ervs=#{counts[:erv]} boilers=#{counts[:b]} chillers=#{counts[:ch]}")
    # --- end user logic ---
    return true
  end
end

ModifyHvac.new.registerWithApplication
