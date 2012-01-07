#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/version';
use Test::More;

no circular::require;
use_ok('Foo');
use_ok('Bar');

done_testing;
