#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/basic';
use Test::More;

use circular::require ();

circular::require->unimport;

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, "Circular require detected: Foo.pm (from Baz.pm)\nCircular require detected: Baz.pm (from Bar.pm)\n", "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Bar');
    is($warnings, "Circular require detected: Baz.pm (from Foo.pm)\nCircular require detected: Bar.pm (from Baz.pm)\n", "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Baz');
    is($warnings, "Circular require detected: Baz.pm (from Foo.pm)\nCircular require detected: Baz.pm (from Bar.pm)\n", "correct warnings");
    clear();
}

circular::require->import;

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, undef, "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Bar');
    is($warnings, undef, "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Baz');
    is($warnings, undef, "correct warnings");
    clear();
}

sub clear {
    for (qw(Foo Bar Baz)) {
        no strict 'refs';
        delete $::{$_};
        delete ${$_ . '::'}{quux};
        delete $INC{"$_.pm"};
    }
}

done_testing;
