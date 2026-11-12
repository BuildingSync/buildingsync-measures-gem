# Shared test infrastructure, not loaded by production measures.
require 'openstudio'
require 'minitest/autorun'
require 'fileutils'
require 'json'

class HvacMeasureTest < Minitest::Test
  ZONE_NAMES = ['Zone One', 'Zone Two', 'Zone Three'].freeze

  def setup
    @measure = self.class::MEASURE_CLASS.new
    @model = load_model(File.join(self.class::TEST_DIR, 'test_model.osm'))
    @run_number = 0
  end

  def load_model(path)
    assert(File.file?(path), "Missing fixture/output model: #{path}")
    translated = OpenStudio::OSVersion::VersionTranslator.new.loadModel(OpenStudio::Path.new(path))
    assert(translated.is_initialized, "Cannot load model: #{path}")
    translated.get
  end

  # Every invocation leaves inspectable artifacts, including intentional failures.
  # Reload the saved output so subsequent assertions also test OSM persistence.
  def run_measure(values = {}, expected: 'Success', error: nil, **argument_values)
    values = values.merge(argument_values)
    @run_number += 1
    output = File.join(self.class::TEST_DIR, 'output', name, @run_number.to_s)
    FileUtils.mkdir_p(output)
    assert(@model.save(OpenStudio::Path.new(File.join(output, 'in.osm')), true))
    # Match the existing direct-test convention. A populated workflow activates
    # SDK stream capture whose runner finalizers can crash under Windows Ruby GC.
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    arguments = OpenStudio::Measure.convertOSArgumentVectorToMap(@measure.arguments(@model))
    values.each do |key, value|
      assert(@measure.arguments(@model).map(&:name).include?(key), "Unknown test argument: #{key}")
      argument = arguments[key].clone
      assert(argument.setValue(value), "Cannot set #{key}=#{value.inspect}")
      arguments[key] = argument
    end
    execution_error = nil
    begin
      returned = @measure.run(@model, runner, arguments)
    rescue StandardError => e
      execution_error = e
    end
    result = runner.result
    details = {
      arguments: values, returned: returned, status: execution_error ? 'Exception' : result.value.valueName,
      exception: execution_error&.full_message,
      errors: result.errors.map(&:logMessage), warnings: result.warnings.map(&:logMessage),
      info: result.info.map(&:logMessage),
      final_condition: result.finalCondition.is_initialized ? result.finalCondition.get.logMessage : nil
    }
    File.write(File.join(output, 'result.json'), JSON.pretty_generate(details))
    output_model = File.join(output, 'out.osm')
    assert(@model.save(OpenStudio::Path.new(output_model), true))
    @model = load_model(output_model)
    raise execution_error if execution_error

    assert_equal(expected, result.value.valueName, details.to_json)
    assert_equal(expected != 'Fail', returned, details.to_json)
    if expected == 'Fail'
      refute_empty(result.errors, 'Expected a diagnostic for an intentional failure')
      assert_match(error, details[:errors].join('\n')) if error
    else
      assert_empty(result.errors, details.to_json)
    end
    result
  end

  def zone(zone_name, model = @model)
    found = model.getThermalZoneByName(zone_name)
    assert(found.is_initialized, "Missing zone: #{zone_name}")
    found.get
  end

  def named(getter, object_name, model = @model)
    object = model.public_send(getter).find { |item| item.nameString == object_name }
    refute_nil(object, "Missing #{object_name} in #{getter}")
    object
  end

  # ModelObjects are compared by complete serialized content, not just counts.
  # Ignore OS:Version, which is not equipment and is refreshed by serialization.
  def snapshot(model = @model)
    model.getModelObjects.map(&:to_s).sort
  end

  def assert_rejected_without_changes(values, error:)
    before = snapshot
    run_measure(values, expected: 'Fail', error: error)
    assert_equal(before, snapshot, 'Rejected input must not partially modify the model')
  end

  def add_baseboard(zone_name)
    baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(@model)
    baseboard.setName("#{zone_name} Existing Baseboard")
    assert(baseboard.addToThermalZone(zone(zone_name)))
    baseboard
  end

  def add_air_loop(zone_names)
    air_loop = OpenStudio::Model::AirLoopHVAC.new(@model)
    air_loop.setName('Existing Shared Air Loop')
    OpenStudio::Model::FanConstantVolume.new(@model).addToNode(air_loop.supplyOutletNode)
    zone_names.each { |zone_name| assert(air_loop.addBranchForZone(zone(zone_name))) }
    air_loop
  end

  def assert_zone_units(model, getter, zone_names)
    units = model.public_send(getter)
    assert_equal(zone_names.size, units.size, getter.to_s)
    assert_equal(zone_names.sort, units.map { |unit| unit.thermalZone.get.nameString }.sort)
    units
  end

  def assert_air_service(model, zone_names, loop_count: 1)
    assert_equal(loop_count, model.getAirLoopHVACs.size)
    assert_equal(zone_names.sort, model.getAirLoopHVACs.flat_map { |loop| loop.thermalZones.map(&:nameString) }.sort)
  end

  def assert_water_coils_connected(model)
    coils = model.getCoilHeatingWaters + model.getCoilCoolingWaters
    refute_empty(coils)
    coils.each { |coil| assert(coil.plantLoop.is_initialized, "Unconnected coil: #{coil.nameString}") }
  end

  def assert_no_new_plants(model)
    assert_empty(model.getPlantLoops.reject { |loop| loop.nameString == 'Unrelated Existing Plant' })
  end

  def assert_translates_as_served(zone_names)
    translator = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = translator.translateModel(@model)
    assert_empty(translator.errors.map(&:logMessage))
    connected = workspace.getObjectsByType('ZoneHVAC:EquipmentConnections'.to_IddObjectType)
                         .map { |object| object.getString(0).get.upcase }
    zone_names.each { |zone_name| assert_includes(connected, zone_name.upcase) }
  end
end