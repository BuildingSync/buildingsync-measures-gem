class ModifySchedules < OpenStudio::Measure::ModelMeasure
  def name
    return "Modify Schedules"
  end

  def description
    return "Create new modified OpenStudio schedules from BuildingSync-aligned schedule detail payloads and assign them directly to occupancy, lighting, plug loads, gas equipment, HVAC availability, and optional additional end uses."
  end

  def modeler_description
    return "Accepts BuildingSync-style schedule payloads with day types, start/end times, and partial operation percentages. Builds new ScheduleRulesets named from the source schedule plus '_modified' and assigns them directly to matching internal loads, air loops, or water-use equipment."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    occupancy_schedule_json = OpenStudio::Measure::OSArgument.makeStringArgument("occupancy_schedule_json", false)
    occupancy_schedule_json.setDisplayName("Occupancy Schedule Payload")
    occupancy_schedule_json.setDescription("Optional BuildingSync schedule payload. Leave blank to keep occupancy schedules unchanged. Supports JSON or compact semicolon-separated text.")
    occupancy_schedule_json.setDefaultValue("")
    args << occupancy_schedule_json
    lighting_schedule_json = OpenStudio::Measure::OSArgument.makeStringArgument("lighting_schedule_json", false)
    lighting_schedule_json.setDisplayName("Lighting Schedule Payload")
    lighting_schedule_json.setDescription("Optional BuildingSync schedule payload for lighting. Leave blank to keep lighting schedules unchanged. Supports JSON or compact semicolon-separated text.")
    lighting_schedule_json.setDefaultValue("")
    args << lighting_schedule_json
    electric_equipment_schedule_json = OpenStudio::Measure::OSArgument.makeStringArgument("electric_equipment_schedule_json", false)
    electric_equipment_schedule_json.setDisplayName("Plug Load Schedule Payload")
    electric_equipment_schedule_json.setDescription("Optional BuildingSync schedule payload for plug or electric equipment. Leave blank to keep these schedules unchanged. Supports JSON or compact semicolon-separated text.")
    electric_equipment_schedule_json.setDefaultValue("")
    args << electric_equipment_schedule_json
    gas_equipment_schedule_json = OpenStudio::Measure::OSArgument.makeStringArgument("gas_equipment_schedule_json", false)
    gas_equipment_schedule_json.setDisplayName("Gas Equipment Schedule Payload")
    gas_equipment_schedule_json.setDescription("Optional BuildingSync gas-equipment payload. Leave blank to keep gas-equipment schedules unchanged. Supports JSON or compact semicolon-separated text.")
    gas_equipment_schedule_json.setDefaultValue("")
    args << gas_equipment_schedule_json
    hvac_availability_schedule_json = OpenStudio::Measure::OSArgument.makeStringArgument("hvac_availability_schedule_json", false)
    hvac_availability_schedule_json.setDisplayName("HVAC Availability Schedule Payload")
    hvac_availability_schedule_json.setDescription("Optional BuildingSync HVAC availability payload. Leave blank to keep air-loop availability schedules unchanged. Supports JSON or compact semicolon-separated text.")
    hvac_availability_schedule_json.setDefaultValue("")
    args << hvac_availability_schedule_json
    additional_schedules_json = OpenStudio::Measure::OSArgument.makeStringArgument("additional_schedules_json", false)
    additional_schedules_json.setDisplayName("Additional Schedule Payloads")
    additional_schedules_json.setDescription("JSON array or compact semicolon-separated payloads for extensible categories such as gas equipment or service water.")
    additional_schedules_json.setDefaultValue("[]")
    args << additional_schedules_json
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    occupancy_schedule_json = runner.getStringArgumentValue("occupancy_schedule_json", user_arguments)
    lighting_schedule_json = runner.getStringArgumentValue("lighting_schedule_json", user_arguments)
    electric_equipment_schedule_json = runner.getStringArgumentValue("electric_equipment_schedule_json", user_arguments)
    gas_equipment_schedule_json = runner.getStringArgumentValue("gas_equipment_schedule_json", user_arguments)
    hvac_availability_schedule_json = runner.getStringArgumentValue("hvac_availability_schedule_json", user_arguments)
    additional_schedules_json = runner.getStringArgumentValue("additional_schedules_json", user_arguments)
    # --- begin user logic ---
    require 'json'

    normalize_hash = lambda do |object|
      return {} unless object.is_a?(Hash)

      normalized = {}
      object.each do |key, value|
        normalized[key.to_s.downcase] = value
      end
      normalized
    end

    fetch_value = lambda do |object, keys, default_value = nil|
      hash = normalize_hash.call(object)
      keys.each do |key|
        normalized_key = key.to_s.downcase
        return hash[normalized_key] if hash.key?(normalized_key)
      end
      default_value
    end

    normalize_target = lambda do |raw_target, fallback_target = nil|
      value = raw_target.to_s.strip
      value = fallback_target.to_s.strip if value.empty? && !fallback_target.nil?
      case value.downcase
      when 'occupied', 'occupancy', 'people', 'numberofpeople'
        'occupancy'
      when 'lighting', 'lights'
        'lighting'
      when 'miscellaneous equipment', 'misc equipment', 'plug load', 'plugload', 'electric equipment', 'electric_equipment'
        'electric_equipment'
      when 'hvac equipment', 'hvac', 'hvac availability', 'availability', 'availability schedule'
        'hvac_availability'
      when 'gas equipment', 'gas', 'gasequipment'
        'gas_equipment'
      when 'service water heating', 'service water', 'water use', 'wateruse', 'shw', 'dhw', 'swh'
        'service_water'
      else
        nil
      end
    end

    parse_clock = lambda do |text|
      parts = text.to_s.strip.split(':')
      return nil unless parts.size == 2 || parts.size == 3

      hour = parts[0].to_i
      minute = parts[1].to_i
      second = parts.size == 3 ? parts[2].to_i : 0
      return nil if hour > 24 || minute > 59 || second > 59
      return nil if hour == 24 && (minute != 0 || second != 0)

      total_seconds = (hour * 3600) + (minute * 60) + second
      total_seconds = 86_400 if total_seconds >= 86_399
      total_seconds
    end

    to_os_time = lambda do |seconds|
      total = seconds.to_i
      total = 86_400 if total >= 86_400
      hour = total / 3600
      minute = (total % 3600) / 60
      second = total % 60
      OpenStudio::Time.new(0, hour, minute, second)
    end

    parse_compact_payload = lambda do |label, payload_text|
      records = payload_text.split(';').map(&:strip).reject(&:empty?)
      payload = {}
      details = []

      records.each do |record|
        if record.include?('=') && !record.include?('|')
          key, value = record.split('=', 2)
          payload[key.to_s.strip.downcase] = value.to_s.strip
        else
          parts = record.split('|').map(&:strip)
          if parts.size != 4
            runner.registerError("#{label} contains an invalid compact record '#{record}'. Expected DayType|HH:MM:SS|HH:MM:SS|Value.")
            return :error
          end
          details << {
            'day_type' => parts[0],
            'start_time' => parts[1],
            'end_time' => parts[2],
            'value_percent' => parts[3]
          }
        end
      end

      payload['details'] = details
      payload
    end

    parse_schedule_payload = lambda do |label, raw_json, default_target|
      payload_text = raw_json.to_s.strip
      return nil if payload_text.empty?

      parsed = nil
      begin
        parsed = JSON.parse(payload_text)
      rescue StandardError
        parsed = parse_compact_payload.call(label, payload_text)
      end
      return :error if parsed == :error

      payload = normalize_hash.call(parsed)
      details = fetch_value.call(payload, %w[details schedule_details], [])
      if !details.is_a?(Array) || details.empty?
        runner.registerError("#{label} must include a non-empty 'details' array.")
        return :error
      end

      target = normalize_target.call(fetch_value.call(payload, %w[target schedule_category category], default_target), default_target)
      if target.nil?
        runner.registerError("#{label} does not map to a supported OpenStudio target.")
        return :error
      end

      schedule_name = fetch_value.call(payload, %w[name schedule_name id], label).to_s.strip
      schedule_name = label if schedule_name.empty?
      spec = {
        'name' => schedule_name,
        'target' => target,
        'details' => []
      }

      details.each do |raw_detail|
        detail = normalize_hash.call(raw_detail)
        day_type = fetch_value.call(detail, %w[day_type daytype], nil)
        start_time = fetch_value.call(detail, %w[start_time daystarttime start], nil)
        end_time = fetch_value.call(detail, %w[end_time dayendtime end], nil)
        raw_value = fetch_value.call(detail, %w[value_percent partialoperationpercentage value fraction], nil)

        if day_type.nil? || start_time.nil? || end_time.nil? || raw_value.nil?
          runner.registerError("#{label} contains a schedule detail missing day type, start time, end time, or value.")
          return :error
        end

        start_seconds = parse_clock.call(start_time)
        end_seconds = parse_clock.call(end_time)
        if start_seconds.nil? || end_seconds.nil?
          runner.registerError("#{label} has an invalid time format. Use HH:MM:SS.")
          return :error
        end
        if end_seconds <= start_seconds
          runner.registerError("#{label} contains an interval where end_time is not later than start_time.")
          return :error
        end

        units = fetch_value.call(detail, %w[value_units units], '')
        numeric_value = raw_value.to_f
        numeric_value = numeric_value / 100.0 if detail.key?('value_percent') || detail.key?('partialoperationpercentage') || units.to_s.downcase == 'percent' || numeric_value > 1.0
        numeric_value = [[numeric_value, 0.0].max, 1.0].min

        spec['details'] << {
          'day_type' => day_type.to_s.strip,
          'start_time' => start_time.to_s,
          'end_time' => end_time.to_s,
          'start_seconds' => start_seconds,
          'end_seconds' => end_seconds,
          'value' => numeric_value
        }
      end

      spec
    end

    apply_intervals = lambda do |schedule_day, intervals, label|
      schedule_day.clearValues
      if intervals.empty?
        schedule_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0.0)
        next true
      end

      sorted = intervals.sort_by { |entry| [entry['start_seconds'], entry['end_seconds']] }
      current_second = 0
      last_value = 0.0

      sorted.each do |entry|
        if entry['start_seconds'] < current_second
          runner.registerError("#{label} has overlapping or out-of-order intervals.")
          return false
        end

        if entry['start_seconds'] > current_second
          schedule_day.addValue(to_os_time.call(entry['start_seconds']), last_value)
        end

        schedule_day.addValue(to_os_time.call(entry['end_seconds']), entry['value'])
        current_second = entry['end_seconds']
        last_value = entry['value']
      end

      if current_second < 86_400
        schedule_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), last_value)
      end

      true
    end

    schedule_specs = []
    core_specs = [
      ['Occupancy Schedule Payload', occupancy_schedule_json, 'occupancy'],
      ['Lighting Schedule Payload', lighting_schedule_json, 'lighting'],
      ['Plug Load Schedule Payload', electric_equipment_schedule_json, 'electric_equipment'],
      ['Gas Equipment Schedule Payload', gas_equipment_schedule_json, 'gas_equipment'],
      ['HVAC Availability Schedule Payload', hvac_availability_schedule_json, 'hvac_availability']
    ]
    core_specs.each do |label, payload_text, target|
      spec = parse_schedule_payload.call(label, payload_text, target)
      return false if spec == :error

      schedule_specs << spec unless spec.nil?
    end

    additional_text = additional_schedules_json.to_s.strip
    if !additional_text.empty? && additional_text != '[]'
      begin
        additional_payload = JSON.parse(additional_text)
      rescue StandardError
        additional_payload = [parse_compact_payload.call('Additional schedule payload', additional_text)]
      end
      return false if additional_payload == :error

      additional_payload = [additional_payload] if additional_payload.is_a?(Hash)
      if !additional_payload.is_a?(Array)
        runner.registerError('Additional Schedule Payloads must be an array or a single object.')
        return false
      end

      additional_payload.each_with_index do |payload, index|
        spec = parse_schedule_payload.call("Additional schedule #{index + 1}", JSON.generate(payload), nil)
        return false if spec == :error

        schedule_specs << spec unless spec.nil?
      end
    end

    if schedule_specs.empty?
      runner.registerAsNotApplicable('No schedule payloads were provided.')
      return true
    end

    fraction_limits = nil
    model.getScheduleTypeLimitss.each do |limits|
      next if limits.name.to_s != 'Fraction'

      fraction_limits = limits
      break
    end
    if fraction_limits.nil?
      fraction_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
      fraction_limits.setName('Fraction')
      fraction_limits.setLowerLimitValue(0.0)
      fraction_limits.setUpperLimitValue(1.0)
      fraction_limits.setNumericType('Continuous')
      fraction_limits.setUnitType('Dimensionless')
    end

    starting_schedule_count = model.getSchedules.size
    created_schedule_names = []
    internal_load_count = 0
    air_loop_count = 0
    water_use_count = 0

    schedule_specs.each do |spec|
      base_generated_name = "#{spec['name']}_modified"
      generated_name = base_generated_name
      existing_names = model.getSchedules.map { |schedule| schedule.name.to_s }
      suffix = 2
      while existing_names.include?(generated_name)
        generated_name = "#{base_generated_name}_#{suffix}"
        suffix += 1
      end

      generated_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
      generated_schedule.setName(generated_name)
      generated_schedule.setScheduleTypeLimits(fraction_limits)

      weekday_intervals = []
      saturday_intervals = []
      sunday_intervals = []
      holiday_intervals = []

      spec['details'].each do |detail|
        case detail['day_type'].downcase
        when 'weekday', 'default'
          weekday_intervals << detail
        when 'saturday', 'sat'
          saturday_intervals << detail
        when 'sunday', 'sun'
          sunday_intervals << detail
        when 'weekend'
          saturday_intervals << detail.dup
          sunday_intervals << detail.dup
        when 'holiday'
          holiday_intervals << detail
        else
          runner.registerWarning("Skipping unsupported day type '#{detail['day_type']}' for schedule '#{generated_name}'.")
        end
      end

      if !apply_intervals.call(generated_schedule.defaultDaySchedule, weekday_intervals, "#{generated_name} weekday")
        return false
      end

      if !saturday_intervals.empty?
        saturday_rule = OpenStudio::Model::ScheduleRule.new(generated_schedule)
        saturday_rule.setName("#{generated_name} Saturday")
        saturday_rule.setApplyMonday(false)
        saturday_rule.setApplyTuesday(false)
        saturday_rule.setApplyWednesday(false)
        saturday_rule.setApplyThursday(false)
        saturday_rule.setApplyFriday(false)
        saturday_rule.setApplySaturday(true)
        saturday_rule.setApplySunday(false)
        if !apply_intervals.call(saturday_rule.daySchedule, saturday_intervals, "#{generated_name} Saturday")
          return false
        end
      end

      if !sunday_intervals.empty?
        sunday_rule = OpenStudio::Model::ScheduleRule.new(generated_schedule)
        sunday_rule.setName("#{generated_name} Sunday")
        sunday_rule.setApplyMonday(false)
        sunday_rule.setApplyTuesday(false)
        sunday_rule.setApplyWednesday(false)
        sunday_rule.setApplyThursday(false)
        sunday_rule.setApplyFriday(false)
        sunday_rule.setApplySaturday(false)
        sunday_rule.setApplySunday(true)
        if !apply_intervals.call(sunday_rule.daySchedule, sunday_intervals, "#{generated_name} Sunday")
          return false
        end
      end

      holiday_source = holiday_intervals.empty? ? sunday_intervals : holiday_intervals
      if !apply_intervals.call(generated_schedule.holidaySchedule, holiday_source, "#{generated_name} Holiday")
        return false
      end

      all_values = spec['details'].map { |detail| detail['value'] }
      design_value = all_values.empty? ? 0.0 : all_values.max
      generated_schedule.winterDesignDaySchedule.clearValues
      generated_schedule.winterDesignDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), design_value)
      generated_schedule.summerDesignDaySchedule.clearValues
      generated_schedule.summerDesignDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), design_value)

      case spec['target']
      when 'occupancy'
        model.getPeoples.each do |people|
          people.setNumberofPeopleSchedule(generated_schedule)
          internal_load_count += 1
        end
      when 'lighting'
        model.getLightss.each do |lights|
          lights.setSchedule(generated_schedule)
          internal_load_count += 1
        end
      when 'electric_equipment'
        model.getElectricEquipments.each do |equipment|
          equipment.setSchedule(generated_schedule)
          internal_load_count += 1
        end
      when 'gas_equipment'
        model.getGasEquipments.each do |equipment|
          equipment.setSchedule(generated_schedule)
          internal_load_count += 1
        end
      when 'hvac_availability'
        model.getAirLoopHVACs.each do |air_loop|
          air_loop.setAvailabilitySchedule(generated_schedule)
          air_loop_count += 1
        end
      when 'service_water'
        model.getWaterUseEquipments.each do |equipment|
          equipment.setFlowRateFractionSchedule(generated_schedule)
          water_use_count += 1
        end
      else
        runner.registerWarning("Skipping unsupported target '#{spec['target']}' for schedule '#{spec['name']}'.")
        next
      end

      created_schedule_names << generated_name
    end

    runner.registerInitialCondition("The model started with #{starting_schedule_count} schedules, #{model.getAirLoopHVACs.size} air loops, and #{model.getWaterUseEquipments.size} water use equipment objects.")
    runner.registerFinalCondition("Created #{created_schedule_names.uniq.size} modified schedules: #{created_schedule_names.uniq.join(', ')}. Applied internal-load schedule targets across #{internal_load_count} load objects, HVAC availability across #{air_loop_count} air loops, and service-water schedules across #{water_use_count} water use equipment objects.")

    true
# --- end user logic ---
    return true
  end
end

ModifySchedules.new.registerWithApplication
