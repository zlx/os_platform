module OSPlatform
  module Platform
    class Linux
      include OSPlatform::Platformable

      def collect_data
        if File.exist?("/etc/oracle-release")
          contents = File.read("/etc/oracle-release").chomp
          @platform = "oracle"
          @platform_version = get_redhatish_version(contents)
        elsif File.exist?("/etc/enterprise-release")
          contents = File.read("/etc/enterprise-release").chomp
          @platform = "oracle"
          @platform_version = get_redhatish_version(contents)
        elsif File.exist?("/etc/debian_version")
          # Ubuntu and Debian both have /etc/debian_version
          # Ubuntu should always have a working lsb, debian does not by default
          if lsb[:id] =~ /Ubuntu/i
            @platform = "ubuntu"
            @platform_version = lsb[:release]
          elsif lsb[:id] =~ /LinuxMint/i
            @platform = "linuxmint"
            @platform_version = lsb[:release]
          else
            if File.exist?("/usr/bin/raspi-config")
              @platform = "raspbian"
            else
              @platform = "debian"
            end
            @platform_version = File.read("/etc/debian_version").chomp
          end
        elsif File.exist?("/etc/parallels-release")
          contents = File.read("/etc/parallels-release").chomp
          @platform = get_redhatish_platform(contents)
          @platform_version = contents.match(/(\d\.\d\.\d)/)[0]
        elsif File.exist?("/etc/redhat-release")
          if File.exist?('/etc/os-release') && (os_release_info = os_release_file_is_cisco? ) # check if Cisco
            @platform = os_release_info['ID']
            @platform_family = os_release_info['ID_LIKE']
            @platform_version = os_release_info['VERSION'] || ""
          else
            contents = File.read("/etc/redhat-release").chomp
            @platform = get_redhatish_platform(contents)
            @platform_version = get_redhatish_version(contents)
          end
        elsif File.exist?("/etc/system-release")
          contents = File.read("/etc/system-release").chomp
          @platform = get_redhatish_platform(contents)
          @platform_version = get_redhatish_version(contents)
        elsif File.exist?('/etc/gentoo-release')
          @platform = "gentoo"
          @platform_version = File.read('/etc/gentoo-release').scan(/(\d+|\.+)/).join
        elsif File.exist?('/etc/SuSE-release')
          suse_release = File.read("/etc/SuSE-release")
          suse_version = suse_release.scan(/VERSION = (\d+)\nPATCHLEVEL = (\d+)/).flatten.join(".")
          suse_version = suse_release[/VERSION = ([\d\.]{2,})/, 1] if suse_version == ""
          @platform_version = suse_version
          if suse_release =~ /^openSUSE/
            @platform = "opensuse"
          else
            @platform = "suse"
          end
        elsif File.exist?('/etc/slackware-version')
          @platform = "slackware"
          @platform_version = File.read("/etc/slackware-version").scan(/(\d+|\.+)/).join
        elsif File.exist?('/etc/arch-release')
          @platform = "arch"
          # no way to determine @platform_version in a rolling release distribution
          # kernel release will be used - ex. 2.6.32-ARCH
          @platform_version = `uname -r`.strip
        elsif File.exist?('/etc/exherbo-release')
          @platform = "exherbo"
          # no way to determine @platform_version in a rolling release distribution
          # kernel release will be used - ex. 3.13
          @platform_version = `uname -r`.strip
        elsif lsb[:id] =~ /RedHat/i
          @platform = "redhat"
          @platform_version = lsb[:release]
        elsif lsb[:id] =~ /Amazon/i
          @platform = "amazon"
          @platform_version = lsb[:release]
        elsif lsb[:id] =~ /ScientificSL/i
          @platform = "scientific"
          @platform_version = lsb[:release]
        elsif lsb[:id] =~ /XenServer/i
          @platform = "xenserver"
          @platform_version = lsb[:release]
        elsif lsb[:id] # LSB can provide odd data that changes between releases, so we currently fall back on it rather than dealing with its subtleties
          @platform = lsb[:id].downcase
          @platform_version = lsb[:release]
        end

        case @platform
        when /debian/, /ubuntu/, /linuxmint/, /raspbian/
          @platform_family = "debian"
        when /fedora/, /pidora/
          @platform_family = "fedora"
        when /oracle/, /centos/, /redhat/, /scientific/, /enterpriseenterprise/, /amazon/, /xenserver/, /cloudlinux/, /ibm_powerkvm/, /parallels/ # Note that 'enterpriseenterprise' is oracle's LSB "distributor ID"
          @platform_family = "rhel"
        when /suse/
          @platform_family = "suse"
        when /gentoo/
          @platform_family = "gentoo"
        when /slackware/
          @platform_family = "slackware"
        when /arch/
          @platform_family = "arch"
        when /exherbo/
          @platform_family = "exherbo"
        end
      end

      private

      def get_redhatish_platform(contents)
        contents[/^Red Hat/i] ? "redhat" : contents[/(\w+)/i, 1].downcase
      end

      def get_redhatish_version(contents)
        contents[/Rawhide/i] ? contents[/((\d+) \(Rawhide\))/i, 1].downcase : contents[/release ([\d\.]+)/, 1]
      end

      def os_release_file_is_cisco?
        return false unless File.exist?('/etc/os-release')
        os_release_info = File.read('/etc/os-release').split.inject({}) do |map, key_value_line|
          key, _separator, value = key_value_line.partition('=')
          map[key] = value
          map
        end
        if os_release_info['CISCO_RELEASE_INFO'] && File.exist?(os_release_info['CISCO_RELEASE_INFO'])
          os_release_info
        else
          false
        end
      end

      def lsb
        return @lsb if @lsb
        @lsb = {}
        if File.exists?("/etc/lsb-release")
          File.open("/etc/lsb-release").each do |line|
            case line
            when /^DISTRIB_ID=["']?(.+?)["']?$/
              @lsb[:id] = $1
            when /^DISTRIB_RELEASE=["']?(.+?)["']?$/
              @lsb[:release] = $1
            when /^DISTRIB_CODENAME=["']?(.+?)["']?$/
              @lsb[:codename] = $1
            when /^DISTRIB_DESCRIPTION=["']?(.+?)["']?$/
              @lsb[:description] = $1
            end
          end
        elsif File.exists?("/usr/bin/lsb_release")
          # Fedora/Redhat, requires redhat-lsb package
          results = `lsb_release -a`
          results.to_s.split("\n").each do |line|
            case line
            when /^Distributor ID:\s+(.+)$/
              @lsb[:id] = $1
            when /^Description:\s+(.+)$/
              @lsb[:description] = $1
            when /^Release:\s+(.+)$/
              @lsb[:release] = $1
            when /^Codename:\s+(.+)$/
              @lsb[:codename] = $1
            else
              @lsb[:id] = line
            end
          end
        end
        @lsb
      end
    end
  end
end
