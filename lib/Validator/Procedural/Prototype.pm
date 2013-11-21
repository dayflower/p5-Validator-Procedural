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
        checkers => {
            NUMERIC => sub { /^\d+$/ || 'INVALID' },
        },
    );

    $prot->register_filter('FOO', sub { ... });

    $prot->register_checker_class('::Common');

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
        checkers => {
            BAR => sub { ... },
        },
        procedures => {
            baz => sub { ... },
        },
    );

Creates prototype.

Optionally filters / checkers / procedures can be specified.

=item create_validator

Generates L<Validator::Procedural> instance from the prototype.

Registerd filter / checker / procedure methods in the prototype will be inherited by generated instances.

Doesn't consume any arguments.  (in current API)

=item register_filter

    $prot->register_filter( FOO => sub { ... } );
    $prot->register_filter(
        FOO => sub { ... },
        BAR => sub { ... },
        ...
    );

Registers filter methods.

Requisites for filter methods are described in L<Validator::Procedural::Filter>.

=item register_checker

    $prot->register_checker( FOO => sub { ... } );
    $prot->register_checker(
        FOO => sub { ... },
        BAR => sub { ... },
        ...
    );

Registers checker methods.

Requisites for checker methods are described in L<Validator::Procedural::Checker>.

=item register_procedure

    $prot->register_procedure( FOO => sub { ... } );
    $prot->register_procedure(
        FOO => sub { ... },
        BAR => sub { ... },
        ...
    );

Registers procedure methods.

Requisites for procedure methods are described in L<Validator::Procedural::Procedure>.

=item register_filter_class

    # register filter methods of Validator::Procedural::Filter::Common
    $prot->register_filter_class('::Common');

    $prot->register_filter_class('MY::Own::Filter::Class');

    # restrict registering methods (like Perl's importer)
    $prot->register_filter_class('::Text', 'TRIM', 'LTRIM');

Register filter methods from specified module.
(Modules will be loaded automatically.)

=item register_checker_class

    # register checker methods of Validator::Procedural::Checker::Common
    $prot->register_checker_class('::Common');

    $prot->register_checker_class('MY::Own::Checker::Class');

    # restrict registering methods
    $prot->register_checker_class('::Number', 'BIG', 'SMALL');

Register checker methods from specified module.
(Modules will be loaded automatically.)

=item register_procedure_class

    # register procedure methods of Validator::Procedural::Procedure::Common
    $prot->register_procedure_class('::Common');

    $prot->register_procedure_class('MY::Own::Procedure::Class');

    # restrict registering methods
    $prot->register_procedure_class('::Text', 'address', 'telephone');

Register procedure methods from specified module.
(Modules will be loaded automatically.)

=back

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>dayflower@cpan.orgE<gt>

=cut

