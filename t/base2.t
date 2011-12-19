#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/base2';
use Test::More;
use Test::Exception;

# Test passes if you comment this out
no circular::require;

use_ok('Foo');
lives_ok { is( Foo->bar, "bar", "Polymorphism" ) }
    "bar() method available on Foo";

throws_ok { base->import( 'BadWolf' ) }
    qr|Base class package "BadWolf" is empty|, "use base 'Some Bad File' should throw an exception";

done_testing;
