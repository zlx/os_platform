module OSPlatform
  module Platform
    class Darwin
      include OSPlatform::Platformable

      def collect_data
        results = `/usr/bin/sw_vers`
        results.to_s.split("\n").each do |line|
          case line
          when /^ProductName:\s+(.+)$/
            macname = $1
            macname.downcase!
            macname.gsub!(" ", "_")
            @platform = macname
          when /^ProductVersion:\s+(.+)$/
            @platform_version = $1
          end
        end

        @platform_family = "mac_os_x"
      end
    end
  end
end
