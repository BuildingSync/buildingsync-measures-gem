# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio/buildingsync_measures/version'
require 'openstudio/extension'

module OpenStudio
  module BuildingsyncMeasures
    class BuildingsyncMeasures < OpenStudio::Extension::Extension
      # Override parent class
      def initialize
        super

        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
      end
    end
  end
end
