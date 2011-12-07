#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/05';
use Test::More;
use Test::Exception;

my @warnings;
$SIG{__WARN__} = sub { push @warnings => @_ };

# Test passes if you comment this out
no circular::require;

use_ok('Foo');

is_deeply(
    \@warnings,
    ["Circular require detected: Foo.pm (from Bar)\n"],
    "Show the module that used base, instead of 'base' when a cycle occurs from a use base."
);

done_testing;
