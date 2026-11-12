# Explicit maintenance utility. Tests always load checked-in fixtures; they never
# silently synthesize a replacement for a missing or unreadable OSM.
require 'openstudio'
require 'fileutils'

module HvacTestFixtures
  MEASURES_DIR = File.expand_path('../../../measures', __dir__)

  def self.base_model
    model = OpenStudio::Model::Model.new
    model.getBuilding.setName('Three-Zone HVAC Unit Test Fixture')
    model.getYearDescription.setCalendarYear(2009)
    example = OpenStudio::Model.exampleModel
    constructions = example.getBuilding.defaultConstructionSet.get.clone(model).to_DefaultConstructionSet.get
    model.getBuilding.setDefaultConstructionSet(constructions)
    example.getDesignDays.each { |day| day.clone(model) }
    heating = OpenStudio::Model::ScheduleConstant.new(model)
    heating.setName('Heating Setpoint 20 C')
    heating.setValue(20.0)
    cooling = OpenStudio::Model::ScheduleConstant.new(model)
    cooling.setName('Cooling Setpoint 26 C')
    cooling.setValue(26.0)
    %w[One Two Three].each_with_index do |suffix, index|
      points = OpenStudio::Point3dVector.new
      [[0, 0], [0, 10], [10, 10], [10, 0]].each do |x, y|
        points << OpenStudio::Point3d.new(x + index * 12, y, 0)
      end
      space = OpenStudio::Model::Space.fromFloorPrint(points, 3.0, model).get
      space.setName("Space #{suffix}")
      zone = OpenStudio::Model::ThermalZone.new(model)
      zone.setName("Zone #{suffix}")
      space.setThermalZone(zone)
      thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
      thermostat.setHeatingSetpointTemperatureSchedule(heating)
      thermostat.setCoolingSetpointTemperatureSchedule(cooling)
      zone.setThermostatSetpointDualSetpoint(thermostat)
      outdoor_air = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
      outdoor_air.setOutdoorAirFlowperFloorArea(0.0005)
      space.setDesignSpecificationOutdoorAir(outdoor_air)
      lights = OpenStudio::Model::LightsDefinition.new(model)
      lights.setWattsperSpaceFloorArea(8.0)
      instance = OpenStudio::Model::Lights.new(lights)
      instance.setSchedule(model.alwaysOnDiscreteSchedule)
      instance.setSpace(space)
    end
    model
  end

  def self.add_modifier_equipment(model)
    # Two independent systems make exact-name scoping and preservation testable.
    %w[One Two].each do |suffix|
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("Air Loop #{suffix}")
      controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
      outdoor_air = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller)
      outdoor_air.addToNode(air_loop.supplyInletNode)
      exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(model)
      exchanger.setName("ERV #{suffix}")
      exchanger.addToNode(outdoor_air.outboardOANode.get)
      OpenStudio::Model::FanConstantVolume.new(model).addToNode(air_loop.supplyOutletNode)
      heating_loop = OpenStudio::Model::PlantLoop.new(model)
      heating_loop.setName("Heating Loop #{suffix}")
      heating_loop.sizingPlant.setLoopType('Heating')
      heating_loop.sizingPlant.setDesignLoopExitTemperature(60.0)
      boiler = OpenStudio::Model::BoilerHotWater.new(model)
      boiler.setName("Boiler #{suffix}")
      boiler.setNominalCapacity(100_000.0)
      heating_loop.addSupplyBranchForComponent(boiler)
      heating_coil = OpenStudio::Model::CoilHeatingWater.new(model)
      heating_loop.addDemandBranchForComponent(heating_coil)
      heating_coil.addToNode(air_loop.supplyOutletNode)
      cooling_loop = OpenStudio::Model::PlantLoop.new(model)
      cooling_loop.setName("Cooling Loop #{suffix}")
      cooling_loop.sizingPlant.setLoopType('Cooling')
      cooling_loop.sizingPlant.setDesignLoopExitTemperature(7.0)
      chiller = OpenStudio::Model::ChillerElectricEIR.new(model)
      chiller.setName("Chiller #{suffix}")
      chiller.setCondenserType('AirCooled')
      chiller.setReferenceCapacity(100_000.0)
      cooling_loop.addSupplyBranchForComponent(chiller)
      cooling_coil = OpenStudio::Model::CoilCoolingWater.new(model)
      cooling_loop.addDemandBranchForComponent(cooling_coil)
      cooling_coil.addToNode(air_loop.supplyOutletNode)
      air_loop.addBranchForZone(model.getThermalZoneByName("Zone #{suffix}").get)
    end
    model
  end

  def self.add_efficiency_components(model)
    # Deliberately isolated components exercise every supported efficiency setter
    # without depending on another measure to construct the test input.
    %w[CoilCoolingDXSingleSpeed CoilCoolingDXTwoSpeed CoilHeatingDXSingleSpeed
       CoilHeatingGas CoilHeatingElectric CoilCoolingWaterToAirHeatPumpEquationFit
       CoilHeatingWaterToAirHeatPumpEquationFit AirConditionerVariableRefrigerantFlow].each do |type|
      %w[One Two].each do |suffix|
        object = OpenStudio::Model.const_get(type).new(model)
        object.setName("#{type} #{suffix}")
      end
    end
    model
  end

  def self.generate
    paths = Dir[File.join(MEASURES_DIR, '{hvac_*,modify_existing_*}', 'measure.rb')].sort
    base = base_model
    paths.each do |path|
      measure_dir = File.dirname(path)
      name = File.basename(measure_dir)
      model = base.clone.to_Model
      add_modifier_equipment(model) if name.start_with?('modify_existing_')
      add_efficiency_components(model) if name == 'modify_existing_hvac_equipment_efficiencies'
      tests = File.join(measure_dir, 'tests')
      FileUtils.mkdir_p(tests)
      destination = File.join(tests, 'test_model.osm')
      raise "Cannot save #{destination}" unless model.save(OpenStudio::Path.new(destination), true)

      puts "Saved #{name}/tests/test_model.osm"
    end
  end
end

HvacTestFixtures.generate if $PROGRAM_NAME == __FILE__