package Validator::Procedural::Rule::General;
use 5.008005;
use strict;
use warnings;

my %Rule = (
    EXISTS   => \&not_null,
    NOT_NULL => \&not_null
);

sub register_to {
    my ($class, $vldr, @labels) = @_;
    unless (@labels) {
        @labels = keys %Rule;
    }

    foreach my $label (@labels) {
        if (exists $Rule{$label}) {
            $vldr->register_rule($label, $Rule{$label});
        }
    }

    return $vldr;
}

sub not_null {
    return if defined $_ && $_ ne "";
    return 'MISSING';
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

