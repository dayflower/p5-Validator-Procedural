package Validator::Procedural::Filter::General;
use 5.008005;
use strict;
use warnings;

my %Filter = (
    TRIM       => \&TRIM,
    FOLD_SPACE => \&FOLD_SPACE,
);

sub register_to {
    my ($class, $vldr, @labels) = @_;
    unless (@labels) {
        @labels = keys %Filter;
    }

    foreach my $label (@labels) {
        if (exists $Filter{$label}) {
            $vldr->register_filter($label, $Filter{$label});
        }
    }

    return $vldr;
}

sub TRIM {
    s{(?: \A \s+ | \s+ \z )}{}gxmso;
    $_;
}

sub FOLD_SPACE {
    s{[ \t]+}{ }gxmso;
    $_;
}

1;
__END__

=encoding utf-8

=head1 NAME

Validator::Procedural::Rule::General - General rules for Validator::Procedural

=head1 SYNOPSIS

    $validator->register_rule_class('::General');

=head1 DESCRIPTION

...

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>dayflower@cpan.orgE<gt>

=cut

