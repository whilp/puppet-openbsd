require 'puppet/provider/package'

PKGHELPER = File::join(File::dirname(__FILE__), "pkghelper.pl")

Puppet::Type.type(:package).provide :openbsd, :parent => Puppet::Provider::Package do
  include Puppet::Util::Execution
  desc "OpenBSD's form of `pkg_add` support."

  commands :pkginfo => "pkg_info", :pkgadd => "pkg_add", :pkgdelete => "pkg_delete"
  commands :perl => "perl"

  defaultfor :operatingsystem => :openbsd
  confine :operatingsystem => :openbsd

  has_feature :versionable

  def query
    for pkg in pkghelper(@resource[:name])
      if pkg[:ensure] == "present"
        return pkg
      end
    end
    return {:ensure => :absent}
  end

  def self.instances
    packages = []
    pkghelper().each do |pkg|
      packages << new(pkg)
    end
    packages
  end

end

def pkghelper(pkgspec = "*-*")
  packages = []
  begin
    output = perl(PKGHELPER, pkgspec)
  rescue Puppet::ExecutionFailure
    return nil
  end

  output.each { |line|
    line.chomp!
    fields = [:ensure, :name, :version, :flavor]
    if match = %r{^(present|absent):(.*)-(\d.*?)(-.*)?$}.match(line)
      hash = {}
      fields.zip(match.captures) {|f,v| hash[f] = v }
      packages << hash
    end
  }

  packages
end

