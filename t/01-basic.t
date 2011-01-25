#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/01';
use Test::More;

no circular::require;

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, "Circular require detected: Foo.pm (from Baz)\nCircular require detected: Baz.pm (from Bar)\n", "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Bar');
    is($warnings, "Circular require detected: Baz.pm (from Foo)\nCircular require detected: Bar.pm (from Baz)\n", "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Baz');
    is($warnings, "Circular require detected: Baz.pm (from Foo)\n", "correct warnings");
    clear();
}

sub clear {
    for (qw(Foo Bar Baz)) {
        delete $::{$_};
        delete $INC{"$_.pm"};
    }
}

done_testing;
