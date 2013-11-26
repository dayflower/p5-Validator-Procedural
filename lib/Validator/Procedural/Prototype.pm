package Validator::Procedural::Prototype;
use 5.008005;
use strict;
use warnings;

use Validator::Procedural;

1;
__END__

=encoding utf-8

=head1 NAME

Validator::Procedural::Prototype - Prototype for Validator::Procedural

=head1 SYNOPSIS

    use Validator::Procedural;

    my $prot = Validator::Procedural::Prototype->new(
        filters => {
            UCFIRST => sub { ucfirst },
        },
        rules => {
            NUMERIC => sub { /^\d+$/ || 'INVALID' },
        },
    );

    $prot->register_filter('FOO', sub { ... });

    $prot->register_rule_class('::Common');

    my $validator = $prot->create_validator();

=head1 DESCRIPTION

This is a prototype class for validator instances.

In web applications for example, it is recommended to create validator prototype once for the application startup, and to generate validator instances from the prototype for each request.

=head1 METHODS

=over 4

=item new

    my $prot = Validator::Procedural::Prototype->new(
        filters => {
            FOO => sub { ... },
        },
        rules => {
            BAR => sub { ... },
        },
        procedures => {
            baz => sub { ... },
        },
    );

Creates prototype.

Optionally filters / rules / procedures can be specified.

=item create_validator

Generates L<Validator::Procedural> instance from the prototype.

Registerd filter / rule / procedure methods and error message formatter in the prototype will be inherited by generated instances.

Doesn't consume any arguments.  (in current API)

=item register_filter

=item register_rule

=item register_procedure

=item register_filter_class

=item register_rule_class

=item register_procedure_class

Above 6 methods are same as L<Validator::Procedural>.
See L<Validator::Procedural/"METHODS"> for illustrations.

=item register_formatter

    $prot->register_formatter( $formatter_instance );

Register error message formatter object.

=back

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>dayflower@cpan.orgE<gt>

=cut

