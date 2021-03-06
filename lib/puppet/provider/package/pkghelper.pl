use OpenBSD::PkgInfo;
use OpenBSD::Search;

my $state = OpenBSD::PkgInfo::State->new("pkg_helper");
for my $pattern (@ARGV) {
    my $spec = OpenBSD::Search::PkgSpec->new($pattern);
    my $r = $state->repo->match_locations($spec);

    # Search for the package spec (see packages-specs(7) on OpenBSD) in a
    # package repository. The repository is built from the PKG_PATH environment
    # variable and may include paths on the network. If the pattern doesn't
    # match at all, its status is "absent".
    for my $p (@$r) {
        my $status = "absent";
        if (OpenBSD::PackageInfo::is_installed($p->name)) {
            $status = "present";
        };
        print $status . "\t" . $pattern . "\t" . $p->name . "\n";
    }
}
