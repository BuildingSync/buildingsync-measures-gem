require_relative '../../../openstudio/buildingsync_measures/test_support/hvac_topology_tests'
require_relative '../measure'

class HvacVentilationOnlyTest < HvacMeasureTest
  MEASURE_CLASS = HvacVentilationOnly
  TEST_DIR = __dir__
  include HvacTopologyTests
  include HvacVentilationTests
end