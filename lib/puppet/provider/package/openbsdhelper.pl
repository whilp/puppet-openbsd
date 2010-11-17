use strict;
use warnings;

use OpenBSD::PackageInfo;
use OpenBSD::PackageName;

sub fmtname
{
	my ($name) = @_;
	my $pkg = OpenBSD::PackageName->from_string($name);
	return $pkg->{stem} . " " . $pkg->{version}->to_string();
}

my @packages = @ARGV;
if (!@packages) {
	@packages = OpenBSD::PackageInfo::installed_packages();
}

for my $pkgname (@packages) {
	print fmtname($pkgname) . "\n";
}
