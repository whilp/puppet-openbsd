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

  def self.prefetch(packages)
    # Invert the packages hash, mapping each unique source to the
    # packages defined with that source.
    sources = Hash.new([])
    packages.each{|name,pkg| sources[pkg[:source]] <<= name}

    # Run pkghelper for each unique source, mapping names to
    # matching hashes.
    names = Hash.new([])
    sources.each{|src, pkgs| pkghelper(src, *pkgs).each{|hash|
      names[hash[:pattern]] <<= hash
    }}

      #packages[pattern].provider = new(hash)
    # For each name, construct a new provider. Each provider is
    # given an array of package hashes that it might later install,
    # remove or whatever.
    for name, hashes in names
      if hashes
        packages[name].provider = new({})
      end
    end

    return


    for source, pkgs in sources
      for hash in pkghelper(source, *pkgs)

      end
    end






    present = Hash.new([])
    absent = Hash.new([])
    sources.each{|s,p| pkghelper(s, *p).each do |hash|
      pattern = hash[:pattern]
      if hash[:ensure] == "present"
        present[pattern] = present[pattern] << hash
      else
        absent[pattern] = absent[pattern] << hash
      end
    }

    for pattern, hashes in absent do
      packages[pattern].provider = new(hash)
        #patterns.each{|p| packages[p].provider = new(hash)}
    end
    for pattern, hashes
    for pattern, hashes in [present, absent].flatten do
    end

    allhashes = Hash.new([])
    sources.each do |source, patterns|
      for hash in pkghelper(source, *patterns)
        allhashes[hash[:pattern]] = allhashes[hash[:pattern]] << hash
      end
    end

    for pattern, hashes in hashes do
      for hash in hashes do
        if hash[:ensure] != "present"
      end
    end

    for hash in hashes do
      if hash[:ensure] != "present"
        hash[:absent]
      end
    end
        patterns.each{|p| packages[p].provider = new(hash)}

    absent.each do |pattern, absents|
      puts ">>> #{packages[pattern].provider@absent}"
      packages[pattern].provider@absent
      #packages[pattern].provider@property_hash[:absent] = absents
    end
  end

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

