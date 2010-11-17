require 'puppet/provider/package'

Puppet::Type.type(:package).provide :openbsd, :parent => Puppet::Provider::Package do
  include Puppet::Util::Execution
  desc "OpenBSD's form of `pkg_add` support."

  commands :pkginfo => "pkg_info", :pkgadd => "pkg_add", :pkgdelete => "pkg_delete"

  defaultfor :operatingsystem => :openbsd
  confine :operatingsystem => :openbsd

  has_feature :versionable

end
