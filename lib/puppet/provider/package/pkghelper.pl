use OpenBSD::PkgInfo;
use OpenBSD::Search;

my $state = OpenBSD::PkgInfo::State->new("pkg_helper");
for my $pattern (@ARGV) {
	my $spec = OpenBSD::Search::PkgSpec->new($pattern);
	my $r = $state->repo->match_locations($spec);

	for my $p (@$r) {
		my $status = "absent";
		if (OpenBSD::PackageInfo::is_installed($p->name)) {
			$status = "present";
		};
		print $status . "\t" . $pattern . "\t" . $p->name . "\n";
	}
}
