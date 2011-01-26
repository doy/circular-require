#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/02';
use Test::More;

no circular::require;
use_ok('Foo');

done_testing;
