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

    my $validator = $prot->create_validator();

=head1 DESCRIPTION

Validator::Procedural::Prototype is ...

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>dayflower@cpan.orgE<gt>

=cut

