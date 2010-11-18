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
    absent = []
    for pkg in pkghelper(@resource[:source], @resource[:name])
      if pkg[:ensure] == "present"
        return pkg
      else
        absent << pkg
      end
    end
    return {:ensure => :absent, :absent => absent}
  end

  def self.prefetch(packages)
  end

  def self.instances
    []
  end

  def install
    for absent in @property_hash[:absent]
      fields = [:name, :version, :flavor]
      pkgname = absent.values_at(*fields).join("-").chomp("-")
      withenv :PKG_PATH => @resource[:source] do
        pkgadd(pkgname)
      end
    end
  end

end

def pkghelper(pkgpath, *pkgspecs)
  packages = []
  output = ''
  begin
    withenv :PKG_PATH => pkgpath do
      output = perl(PKGHELPER, *pkgspecs)
    end
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

