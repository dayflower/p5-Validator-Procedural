# NAME

Validator::Procedural - Procedural validator

# SYNOPSIS

    use Validator::Procedural;

    # create validator prototype with given filters / checkers.
    my $prot = Validator::Procedural::Prototype->new(
        filters => {
            UCFIRST => sub { ucfirst },
        },
        checkers => {
            NUMERIC => sub { /^\d+$/ || 'INVALID' },
        },
    );

    # filter plugins can be applied to validator (prototypes).
    Validator::Procedural::Filter::Common->register_to($prot, 'TRIM', 'LTRIM');
    # also checker plugins can be
    Validator::Procedural::Checker::Common->register_to($prot);

    # filter class registration can be called from validator (prototypes).
    # package begins with '::' is recognized under 'Validator::Procedural::Filter::' namespace.
    $prot->register_filter_class('::Japanese', 'HAN2ZEN');
    $prot->register_filter_class('MY::Own::Filter');
    # also for checker class registration
    # package begins with '::' is recognized under 'Validator::Procedural::Checker::' namespace.
    $prot->register_checker_class('::Date');
    $prot->register_checker_class('MY::Own::Checker', 'MYCHECKER');

    # you can register filters (and checkers) after instantiation of prototype
    $prot->register_filter(
        TRIM => sub { s{ (?: \A \s+ | \s+ \z ) }{}gxmso; $_ },
    );

    $prot->register_checker(
        EMAIL => sub {
            # Of course this is not precise for email address, but just example.
            unless (m{\A \w+ @ \w+ (?: \. \w+ )+ \z}xmso) {
                return 'INVALID';   # error code for errors
            }

            return;                 # (undef) for OK
        },
    );

    # can register common filtering and checking procedure (not required)
    $prot->register_procedure('DATETIME', sub {
        my ($field) = @_;

        # apply filters
        $field->apply_filter('TRIM');

        # apply checkers
        return unless $field->check('EXISTS');
    });

    # register error message formatter (default is Validator::Procedural::Formatter::Minimal)
    $prot->register_formatter(Validator::Procedural::Formatter::Minimal->new());

    # now create validator (with state) from prototype
    my $validator = $prot->create_validator();

    # process for field 'bar' by custom procedure
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

    # can apply registered procedure with given value
    $validator->process('foo', 'DATETIME', $req->param('foo'));



    # can retrieve validation result anytime

    $validator->success();      # => TRUE or FALSE
    $validator->has_error();    # => ! success()

    # retrieve fields and errors mapping
    $validator->errors();
    # => errors in Array or Hash-ref (for scalar context); (
    #     foo => [ 'MISSING', 'INVALID_DATE' ],
    # )

    $validator->invalid_fields();
    # => fields in Array; ( 'foo', 'bar' )

    # can filter fields that has given error code
    $validator->invalid_fields('MISSING');
    # => fields in Array; ( 'foo', 'bar' )

    # error code filtering rule can be supplied with subroutine
    $validator->invalid_fields(sub { grep { $_ eq 'MISSING' } @_ });
    # => fields in Array; ( 'foo', 'bar' )

    # retrieve error codes (or empty for valid field)
    $validator->error('foo');
    # => errors for field in Array;
    #    ( 'MISSING', 'INVALID_DATE' )

    $validator->valid('foo');   # => TRUE of FALSE
    $validator->invalid('foo'); # => ! valid()

    # clear error
    $validator->clear_errors('foo');

    # append error (manually)
    $validator->add_error('foo', 'MISSING');

    # retrieve filtered value for specified field
    $validator->value('foo');
    # retrieve all values filtered
    $validator->values();
    # => values in Array or Hash-ref (for scalar context); (
    #     foo => [ 'val1', 'val2' ],
    #     var => [ 'val1' ],            # always in Array-ref for single value
    # )

    # retrieve error messages for all fields
    $validator->error_messages();
    # retrieve error message(s) for given field
    $validator->error_message('foo');

# DESCRIPTION

Validator::Procedural is yet another validation module.

# MOTIVATION FOR YET ANOTHER VALIDATION MODULE

There are so many validation modules on CPAN.  Why yet another one?

Some of modules provide good-looking feature with simple configuration, but when I used those modules for compositing several fields and filtering fields (and for condition of some fields depending on other field), some were not able to handle such situation, some required custom handler.

So I focused on following points for design this module.

- To provide compact but sufficient container for validation result
- To provide filtering mechanism and functionality to retrieve filtered parameters
- To depend on other modules as least as possible (complex validators and filters depending on other modules heavyly will be supplied as dependent plugin distributions)

This module DOES NOT provide easy configuration.  But you have to implement validation procedure with Perl code, so on such a complex condition described above, you can make codes straightforwardly, easy to understand.

# LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

ITO Nobuaki <daydream.trippers@gmail.com>
