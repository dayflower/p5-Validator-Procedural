# NAME

Validator::Procedural - Procedural validator

# SYNOPSIS

    use Validator::Procedural;

    my $mech = Validator::Procedural->new();

    Validator::Procedural::Filter::Common->register_to($mech, 'TRIM', 'LTRIM');
    Validator::Procedural::Checker::Common->register_to($mech);

    $mech->register_filter_class('Japanese', 'HAN2ZEN');
    $mech->register_filter_class('+MY::Own::Filter');
    $mech->register_checker_class('Date');
    $mech->register_checker_class('+MY::Own::Checker', 'MYCHECKER');

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
        my ($field) = @_;

        # apply filters
        $field->apply_filters('TRIM');

        # apply checkers
        return unless $field->check('EXISTS');
    });

    my $validator = $mech->create_validator();

    $validator->process('foo', 'DATETIME', $req->param('foo'));

    $validator->process('bar', sub {
        my ($field) = @_;

        # set value
        $field->value($req->param('bar'));

        # apply filters
        $field->apply_filters('TRIM');

        # filter value manually
        my $val = $field->value();
        $field->value($val . ' +0000');

        # apply checkers
        return unless $field->check('EXISTS');
        return unless $field->check_all('EXISTS', \&checker);

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

    $validator->value('foo');
    $validator->values();

    # use Validator::Procedural::ErrorMessage for error messages.

# DESCRIPTION

Validator::Procedural is ...

# MOTIVATION FOR YET ANOTHER VALIDATION MODULE

Validator::Procedural is ...

# LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ITO Nobuaki <daydream.trippers@gmail.com>
