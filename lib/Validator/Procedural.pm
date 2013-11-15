package Validator::Procedural;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub register_filter {
    my $self = shift;
}

sub register_checker {
    my $self = shift;
}

sub register_procedure {
    my $self = shift;
}

sub create_validator {
    my $self = shift;
}

package Validator::Procedural::Validator;

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub register_filter {
    my $self = shift;
}

sub register_checker {
    my $self = shift;
}

sub register_procedure {
    my $self = shift;
}

sub process {
    my $self = shift;
}

sub success {
}

sub has_error {
}

sub errors {
}

sub error {
}

sub valid {
}

sub invalid {
}

sub clear_errors {
}

sub set_errors {
}

sub add_error {
}

package Validator::Procedural::State;

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub value {
}

sub apply_filters {
}

sub check {
}

sub errors {
}

sub clear_errors {
}

sub set_errors {
}

sub add_error {
}

1;
__END__

=encoding utf-8

=head1 NAME

Validator::Procedural - Procedural validator

=head1 SYNOPSIS

    use Validator::Procedural;

    my $mech = Validator::Procedural->new();

    Validator::Procedural::Filter::Common->register_to($mech);
    Validator::Procedural::Checker::Common->register_to($mech);

    $mech->register_filter(
        TRIM => sub {
            s{ (?: \A \s+ | \s+ \z ) }{}gxmso;
        },
    );

    $mech->register_checker(
        EMAIL => sub {
            # Of course this pattern is not strict for email, but It's example.
            unless (m{\A \w+ @ \w+ (?: \. \w+ )+ \z}xmso) {
                return 'INVALID';   # error code for errors
            }

            return;                 # (undef) for OK
        },
    );

    $mech->register_procedure('DATETIME', sub {
        my ($state) = @_;

        # apply filters
        $state->apply_filters('TRIM');

        # apply checkers
        return unless $state->check('EXISTS');
    });

    my $validator = $mech->create_validator();

    $validator->process('foo', 'DATETIME', $req->param('foo'));

    $validator->process('bar', sub {
        my ($state) = @_;

        # set value
        $state->value($req->param('bar'));

        # apply filters
        $state->apply_filters('TRIM');

        # filter value manually
        my $val = $state->value();
        $state->value($val . ' +0000');

        # apply checkers
        return unless $state->check('EXISTS');

        # check value manually
        eval {
            use Time::Piece;
            Time::Piece->strptime($state->value, '%Y-%m-%d %z');
        };
        if ($@) {
            $state->add_error('INVALID_DATE');
            return;
        }
    });

    $validator->success();      # => TRUE or FALSE
    $validator->has_error();    # => ! success()

    $validator->errors();
    # => errors in Array; (
    #     foo => [ 'MISSING', 'INVALID_DATE' ],
    # )

    $validator->error_fields();
    # => fields in Array; ( 'foo', 'bar' )

    $validator->error_fields('MISSING');
    # => fields in Array; ( 'foo', 'bar' )

    $validator->error_fields(sub { grep { $_ eq 'MISSING' } @_ });
    # => fields in Array; ( 'foo', 'bar' )

    $validator->error('foo');
    # => errors for field in Array;
    #    ( 'MISSING', 'INVALID_DATE' )

    $validator->valid('foo');   # => TRUE of FALSE
    $validator->invalid('foo'); # => ! valid()

    # clear error
    $validator->clear_errors('foo');

    # append error
    $validator->add_error('foo', 'MISSING');

    # use Validator::Procedural::ErrorMessage for error messages.

=head1 DESCRIPTION

Validator::Procedural is ...

=head1 MOTIVATION FOR YET ANOTHER VALIDATION MODULE

Validator::Procedural is ...

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>daydream.trippers@gmail.comE<gt>

=cut

