require "os_platform/version"
require "rubygems/platform"
require "os_platform/platform"

module OSPlatform
  class << self
    def local
      @os = Gem::Platform.local.os
      if @os.respond_to?(:capitalize) && OSPlatform.const_defined?("Platform::#{@os.capitalize}")
        klass = OSPlatform.const_get("Platform::#{@os.capitalize}").send(:new)
        klass.collect_data
        klass
      else
        fail "Not Support Platform For #{@os} Now, please submit bug on https://github.com/zlx/os_platform/issues."
      end
    end
  end
end
