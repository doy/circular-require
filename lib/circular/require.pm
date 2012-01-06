package circular::require;
use strict;
use warnings;
# ABSTRACT: detect circularity in use/require statements

use Package::Stash;
# XXX would be nice to load this on demand, but "on demand" is within the
# require override, which causes a mess (on pre-5.14)
use B;

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

This module works as a pragma, and typically pragmas have lexical scope.
Lexical scope doesn't make a whole lot of sense for this case though, because
the effect it's tracking isn't lexical (what does it mean to disable the pragma
inside of a cycle vs. outside of a cycle? does disabling it within a cycle
cause it to always be disabled for that cycle, or only if it's disabled at the
point where the warning would otherwise be generated? etc.), but dynamic scope
(the scope that, for instance, C<local> uses) does, and that's how this module
works. Saying C<no circular::require> enables the module for the current
dynamic scope, and C<use circular::require> disables it for the current dynamic
scope. Hopefully, this will just do what you mean.

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

sub _find_enable_state {
    my $depth = 0;
    while (defined(scalar(caller(++$depth)))) {
        my $hh = (caller($depth))[10];
        next unless defined $hh;
        next unless exists $hh->{'circular::require'};
        return $hh->{'circular::require'};
    }
    return 0;
}

sub _require {
    my ($file) = @_;
    # on 5.8, if a value has both a string and numeric value, require will
    # treat it as a vstring, so be sure we don't use the incoming value in
    # string contexts at all
    my $string_file = $file;
    if (exists $loaded_from{$string_file}) {
        my @cycle = ($string_file);

        my $caller = $previous_file;

        while (defined($caller)) {
            unshift @cycle, $caller
                unless grep { /^$caller$/ } @hide;
            last if $caller eq $string_file;
            $caller = $loaded_from{$caller};
        }

        if (_find_enable_state()) {
            if (@cycle > 1) {
                warn "Circular require detected:\n  " . join("\n  ", @cycle) . "\n";
            }
            else {
                warn "Circular require detected in $string_file (from unknown file)\n";
            }
        }
    }
    local $loaded_from{$string_file} = $previous_file;
    local $previous_file = $string_file;
    my $ret;
    # ugh, base.pm checks against the regex
    # /^Can't locate .*? at \(eval / to see if it should suppress the error
    # but we're not in an eval anymore
    # fake it up so that this looks the same
    if (defined((caller(1))[6])) {
        my $str = B::perlstring($file);
        $ret = $saved_require_hook
            ? $saved_require_hook->($file)
            : (eval "CORE::require($str)" || die $@);
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
    # not delete, because we want to see it being explicitly disabled
    $^H{'circular::require'} = 0;
}

sub unimport {
    my $class = shift;
    my %params = @_;

    @hide = ref($params{'-hide'}) ? @{ $params{'-hide'} } : ($params{'-hide'})
        if exists $params{'-hide'};
    @hide = map { /\.pm$/ ? $_ : _mod2pm($_) } @hide;

    my $stash = Package::Stash->new('CORE::GLOBAL');
    my $old_require = $stash->get_package_symbol('&require');
    $saved_require_hook = $old_require
        if defined($old_require) && $old_require != \&_require;
    $stash->add_package_symbol('&require', \&_require);
    $^H{'circular::require'} = 1;
}

sub _mod2pm {
    my ($mod) = @_;
    $mod =~ s+::+/+g;
    $mod .= '.pm';
    return $mod;
}

=head1 CAVEATS

This module works by overriding C<CORE::GLOBAL::require>, and so other modules
which do this may cause issues if they aren't written properly.

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
