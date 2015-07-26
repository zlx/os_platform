require 'singleton'

module OSPlatform
  module Platformable
    attr_reader :platform, :platform_version, :platform_family

    def collect_data
      fail NotImplementedError, "Should implement collect_data in subclass"
    end
  end
end
