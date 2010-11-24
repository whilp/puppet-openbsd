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
    # Create a hash that uses a (new) array for missing keys.
    defaulthash = Hash.new { |h, k| [] }

    # Aggregate packages by their source so that we can make the
    # fewest possible trips to the network (:source == PKG_PATH).
    sources = defaulthash.dup
    packages.each { |name, pkg| sources[pkg[:source]] <<= pkg }

    # Run pkghelper on all of the patterns we got, parsing its
    # output and doing a bit of prep on the match hashes.
    matches = defaulthash.dup
    sources.each { |src, pkgs| 
      pkghelper(src, *pkgs.collect { |p| p[:name] }).each { |match|
        match[:ensure] = match[:ensure].intern
        matches[match[:pattern]] <<= match
    }}

    # Each pattern may produce any number of matches, so store the
    # array of matches in an attribute for the other methods to
    # access later.
    for pattern, matchset in matches
      packages[pattern].provider.matches = matchset
    end

  end

  def query
    for pkg in mismatches
      return {:ensure => pkg[:ensure]}
    end
    return {:ensure => @resource[:ensure]}
  end

  def mismatches
    mismatches = []
    for pkg in @matches
      mismatches << pkg if pkg[:ensure] != @resource[:ensure]
    end
    return mismatches
  end

  def install
    packages = mismatches.collect { |p| p[:pkgname] }
    withenv :PKG_PATH => @resource[:source] do
      pkgadd(*packages)
    end
  end

  def uninstall
    packages = mismatches.collect { |p| p[:pkgname] }
    withenv :PKG_PATH => @resource[:source] do
      pkgdelete(*packages)
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
      fields.zip(match.captures) {|f,v| hash[f] = v ? v.gsub(/(^-|-$)/, '') : v }
      hash[:pkgname] = hash.values_at(:name, :version, :flavor).join("-").chomp("-")
      packages << hash
    end
  }

  packages
end
