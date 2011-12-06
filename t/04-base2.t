#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/04';
use Test::More;

# Test passes if you comment this out
no circular::require;

use_ok('Foo');
is( Foo->bar, "bar", "Polymorphism" );

done_testing;
