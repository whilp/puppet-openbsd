require 'puppet/provider/package'

Puppet::Type.type(:package).provide :openbsd, :parent => Puppet::Provider::Package do
  include Puppet::Util::Execution
  desc "OpenBSD's form of `pkg_add` support."

  commands :pkginfo => "pkg_info", :pkgadd => "pkg_add", :pkgdelete => "pkg_delete"
  commands :perl => "perl"
  pkghelper = File::join(File::dirname(__FILE__), "pkghelper.pl")

  defaultfor :operatingsystem => :openbsd
  confine :operatingsystem => :openbsd

  has_feature :versionable

  def query
    packages = []
    begin
      output = perl(:pkginfo, "-e", @resource[:name])
    rescue Puppet::ExecutionFailure
       return nil
    end

    output.each { |line|
      line.chomp!
      fields = [:stem, :version, :flavor]
      if match = %r{^inst:(.*)-(\d.*?)(-.*)?$}.match(line)
        hash = {}
        fields.zip(match.captures) { | field, value|
            hash[field] = value
        }
        packages << new(hash)
      end
    }

    packages
  end
end
