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

  attr_accessor :matches

  def self.prefetch(packages)
    defaulthash = Hash.new { |h, k| [] }
    # Invert the packages hash, mapping each unique source to the
    # packages defined with that source. This allows us to make the
    # fewest number of calls to pkghelper (and, possibly, to a slow
    # resource on the net defined in PKG_PATH).

    sources = defaulthash.dup
    packages.each { |name, pkg| sources[pkg[:source]] <<= pkg }
  end

  def query
    for pkg in @matches
      #puts ">>> #{pkg[:pattern]} #{pkg[:name]} #{pkg[:ensure]}"
    end


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

# Inline withenv() for pkghelper.
def withenv(hash)
  oldvals = {}
  hash.each do |name, val|
    name = name.to_s
    oldvals[name] = ENV[name]
    ENV[name] = val
  end

  yield
ensure
  oldvals.each do |name, val|
    ENV[name] = val
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
    fields = [:ensure, :pattern, :name, :version, :flavor]
    if match = %r{^(present|absent)\t([^ ]*)\t(.*)-(\d.*?)(-.*)?$}.match(line)
      hash = {}
      fields.zip(match.captures) {|f,v| hash[f] = v }
      packages << hash
    end
  }

  packages
end
