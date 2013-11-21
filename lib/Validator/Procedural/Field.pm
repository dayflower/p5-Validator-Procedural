package Validator::Procedural::Field;
use 5.008005;
use strict;
use warnings;

use Validator::Procedural;

1;
__END__

=encoding utf-8

=head1 NAME

Validator::Procedural::Field - Field for Validator::Procedural

=head1 SYNOPSIS

    $validator->process('bar', sub {
        my ($field) = @_;

        # set value
        $field->value($req->param('bar'));

        # apply filters
        $field->apply_filter('TRIM');

        # filter value manually
        my $val = $field->value();
        $field->value($val . ' +0000');

        # apply checkers
        return unless $field->check('EXISTS');

        # check value manually
        eval {
            require Time::Piece;
            Time::Piece->strptime($field->value, '%Y-%m-%d %z');
        };
        if ($@) {
            $field->add_error('INVALID_DATE');
            return;
        }
    });

=head1 DESCRIPTION

This is the field class of L<Validator::Procedural>.

You will use instances of this class in validation "procedure"s, so you do not have to C<use> L<Validator::Procedural::Field> directly.

=head1 METHODS

=over 4

=item label

Returns field label.

=item value

    my $val = $field->value();

    $field->value(undef);           # unset value for field
    $field->value('foo');
    $field->value('foo', 'bar');    # can set multiple values for field

Gets and sets field value.

=item apply_filter

    $field->apply_filter('TRIM');           # apply registered filter
    $field->apply_filter(sub { ... });
    $field->apply_filter('X', times => 3);  # can supply options for filter

Applies filter to field value.

=item check

    $field->check('TRIM');              # call registered checker
    $field->check(sub { ... });
    $field->check('GT', than => 3);     # can supply options for checker

Checks field value.

Returns C<1> (true) for success, C<0> (false) for failure.
So you can stop further validations on failure by checking result.
Also you can continue validations.

=item error

Returns current error codes for the field.

=item add_error

    $field->add_error('INVALID');
    $field->add_error('UGLY', 'BAD');   # can supply multiple codes

Appends error code(s) for the field.

=item clear_errors

Clears error codes for the field.

=item set_errors

    $field->set_error('INVALID');
    $field->set_error('UGLY', 'BAD');   # can supply multiple codes

Sets error code(s) for the field.

And clears current error codes, so this is discouraged to use for normal conditions.

=back

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>dayflower@cpan.orgE<gt>

=cut

