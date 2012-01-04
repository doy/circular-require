#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/hide_middleman';
use Test::More;

no circular::require -hide => ['base', 'parent'];

my @warnings;

{
    $SIG{__WARN__} = sub { push @warnings => @_ };

    use_ok( 'Foo' );
}

is_deeply(
    \@warnings,
    ["Circular require detected: Foo.pm (from Bar.pm)\n"],
    "Show the module that used base, instead of 'base' when a cycle occurs from a use base."
);

done_testing;
