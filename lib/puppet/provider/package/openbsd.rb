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
    if do_pkginfo(@resource[:name])
      return {:ensure => :installed}
    end
  end

  def self.instances
    packages = []
    do_pkginfo().each do |pkg|
        pkg[:ensure] = :installed
        packages << new(pkg)
    end
    packages
  end

end

def do_pkginfo(pkgspec = "*-*")
  packages = []
  begin
    output = pkginfo("-e", pkgspec)
  rescue Puppet::ExecutionFailure
     return nil
  end

  output.each { |line|
    line.chomp!
    fields = [:name, :version, :flavor]
    if match = %r{^inst:(.*)-(\d.*?)(-.*)?$}.match(line)
      hash = {}
      fields.zip(match.captures) {|f,v| hash[f] = v }
      packages << hash
    end
  }

  packages
end
