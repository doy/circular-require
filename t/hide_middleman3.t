#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/hide_middleman';
use Test::More;

no circular::require -hide => [
    qw(base Foo Bar main circular::require),
    (map { my $m = $_; $m =~ s+/+::+g; $m =~ s/\.pm$//; $m } keys %INC),
];

my @warnings;

{
    $SIG{__WARN__} = sub { push @warnings => @_ };

    use_ok( 'Foo' );
}

is_deeply(
    \@warnings,
    ["Circular require detected: Foo.pm (from <unknown file>)\n"],
    "don't loop infinitely if all packages are hidden"
);

done_testing;
