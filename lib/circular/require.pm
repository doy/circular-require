package circular::require;
use strict;
use warnings;
# ABSTRACT: detect circularity in use/require statements

use Package::Stash;

=head1 SYNOPSIS

  package Foo;
  use Bar;

  package Bar;
  use Foo;

  package main;
  no circular::require;
  use Foo; # warns

or

  perl -M-circular::require foo.pl

=head1 DESCRIPTION

Perl by default just ignores cycles in require statements - if Foo.pm does
C<use Bar> and Bar.pm does C<use Foo>, doing C<use Foo> elsewhere will start
loading Foo.pm, then hit the C<use> statement, start loading Bar.pm, hit the
C<use> statement, notice that Foo.pm has already started loading and ignore it,
and continue loading Bar.pm. But Foo.pm hasn't finished loading yet, so if
Bar.pm uses anything from Foo.pm (which it likely does, if it's loading it),
those won't be accessible while the body of Bar.pm is being executed. This can
lead to some very confusing errors, especially if introspection is happening at
load time (C<make_immutable> in L<Moose> classes, for example). This module
generates a warning whenever a module is skipped due to being loaded, if that
module has not finished executing.

=cut

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

=head1 CAVEATS

This module works by overriding C<CORE::GLOBAL::require>, and so other modules
which do this may cause issues if they aren't written properly. This also means
that the effect is global, but this is typically the most useful usage.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-circular-require at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=circular-require>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc circular::require

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/circular-require>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/circular-require>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=circular-require>

=item * Search CPAN

L<http://search.cpan.org/dist/circular-require>

=back

=cut

1;
