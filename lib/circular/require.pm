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

In some situations, other modules might be handling the module loading for
you - C<use base> and C<Class::Load::load_class>, for instance. To avoid these
modules showing up as the source of cycles, you can use the C<-hide> parameter
when using this module. For example:

  no circular::require -hide => [qw(base parent Class::Load)];

or

  perl -M'-circular::require -hide => [qw(base parent Class::Load)];' foo.pl

=cut

our %loaded_from;
our $previous_file;
my $saved_require_hook;
my @hide;

sub _require {
    my ($file) = @_;
    # on 5.8, if a value has both a string and numeric value, require will
    # treat it as a vstring, so be sure we don't use the incoming value in
    # string contexts at all
    my $string_file = $file;
    if (exists $loaded_from{$string_file}) {
        my $caller = $previous_file;

        while (grep { m/^$caller$/ } @hide) {
            $caller = $loaded_from{$caller};
            if (!defined($caller) || $caller eq $string_file) {
                $caller = '<unknown file>';
                last;
            }
        }

        warn "Circular require detected: $string_file (from $caller)\n";
    }
    local $loaded_from{$string_file} = $previous_file;
    local $previous_file = $string_file;
    my $ret;
    # ugh, base.pm checks against the regex
    # /^Can't locate .*? at \(eval / to see if it should suppress the error
    # but we're not in an eval anymore
    # fake it up so that this looks the same
    if (defined((caller(1))[6])) {
        my $mod = _pm2mod($file);
        $ret = $saved_require_hook
            ? $saved_require_hook->($file)
            : (eval "CORE::require $mod" || die $@);
    }
    else {
        $ret = $saved_require_hook
            ? $saved_require_hook->($file)
            : CORE::require($file);
    }
    return $ret;
}

sub import {
    my $stash = Package::Stash->new('CORE::GLOBAL');
    if ($saved_require_hook) {
        $stash->add_package_symbol('&require' => $saved_require_hook);
    }
    else {
        $stash->remove_package_symbol('&require');
    }
}

sub unimport {
    my $class = shift;
    my %params = @_;

    @hide = ref($params{'-hide'}) ? @{ $params{'-hide'} } : ($params{'-hide'})
        if exists $params{'-hide'};
    @hide = map { /\.pm/ ? $_ : _mod2pm($_) } @hide;

    my $stash = Package::Stash->new('CORE::GLOBAL');
    my $old_require = $stash->get_package_symbol('&require');
    $saved_require_hook = $old_require
        if defined($old_require) && $old_require != \&_require;
    $stash->add_package_symbol('&require', \&_require);
}

sub _mod2pm {
    my ($mod) = @_;
    $mod =~ s+::+/+g;
    $mod .= '.pm';
    return $mod;
}

sub _pm2mod {
    my ($file) = @_;
    $file =~ s+/+::+g;
    $file =~ s+\.pm$++;
    return $file;
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

=begin Pod::Coverage

unimport

=end Pod::Coverage

=cut

1;
