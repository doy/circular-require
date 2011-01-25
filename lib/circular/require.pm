package circular::require;
use strict;
use warnings;
use Package::Stash;

my %seen;
my $saved;

sub _require {
    my ($file) = @_;
    if (exists $seen{$file} && !$seen{$file}) {
        warn "Circular require detected: $file (from " . caller() . ")\n";
    }
    $seen{$file} = 0;
    my $ret = $saved ? $saved->($file) : CORE::require($file);
    $seen{$file} = 1;
    return $ret;
}

sub import {
    my $stash = Package::Stash->new('CORE::GLOBAL');
    if ($saved) {
        $stash->add_package_symbol('&require' => $saved);
    }
    else {
        $stash->remove_package_symbol('&require');
    }
}

sub unimport {
    my $stash = Package::Stash->new('CORE::GLOBAL');
    my $old_require = $stash->get_package_symbol('&require');
    $saved = $old_require
        if defined($old_require) && $old_require != \&_require;
    $stash->add_package_symbol('&require', \&_require);
}

1;
