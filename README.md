# NAME

Validator::Procedural - Procedural validator

# SYNOPSIS

    use Validator::Procedural;

    # create prototype of validator
    my $prot = Validator::Procedural::Prototype->new(
        filters => {
            UCFIRST => sub { ucfirst },
        },
        rules => {
            NUMERIC => sub { /^\d+$/ || 'INVALID' },
        },
    );

    $prot->register_filter_class('::General');
    $prot->register_rule_class('::General', 'EXISTS');

    # now create validator from prototype
    my $validator = $prot->create_validator();

    # validate 'bar' field
    $validator->process('bar', sub {
        my ($field) = @_;

        # set value
        $field->value($req->param('bar') . $req->param('baz'));

        # apply filters
        $field->apply_filter('TRIM');
        $field->apply_filter('UCFIRST');

        # apply rules
        return unless $field->check('EXISTS');
    });

    # retrieve validation result
    my $results = $validator->results;

    if ($results->has_error()) {
        use JSON;

        return encode_json({
            invalids => [ $results->invalid_fields() ],
            messages => [ $results->error_messages() ],
        });
    }

# DESCRIPTION

Validator::Procedural is yet another validation module.

THIS MODULE IS CURRENTLY ON WORKING DRAFT PHASE.  API MAY CHANGE.

# MOTIVATION FOR YET ANOTHER VALIDATION MODULE

There are so many validation modules on CPAN.  Why yet another one?

Some of such modules provide good-looking features with simple configuration. But when I used those modules for compositing several fields and filtering fields (and for condition of some fields depending on other field), some were not able to handle such situation, some required custom handler.

So I focused on following points for design this module.

- To provide compact but sufficient container for validation results
- To provide filtering mechanism and functionality to retrieve filtered values from results
- To depend on other modules as least as possible (complex validators and filters depending on other modules heavyly should be supplied as dependent plugin distributions)
- To make error message formatter independent of validator

This module is NOT all-in-one validation product.  This module DOES NOT provide easy configuration.  But you have to implement validation procedure with Perl code, so on such a complex condition described above, you can write codes straightforwardly, easy to understand.

# METHODS

- register\_filter

        $validator->register_filter(
            FOO => sub { ... },
            BAR => sub { ... },
            ...
        );

    Registers filter methods.

    Requisites for filter methods are described in ["REQUISITES FOR FILTER METHODS"](#REQUISITES FOR FILTER METHODS).

- register\_rule

        $validator->register_rule(
            FOO => sub { ... },
            BAR => sub { ... },
            ...
        );

    Registers rule methods.

    Requisites for rule methods are described in ["REQUISITES FOR RULE METHODS"](#REQUISITES FOR RULE METHODS).

- register\_procedure

        $validator->register_procedure(
            foo => sub { ... },
            bar => sub { ... },
            ...
        );

    Registers procedure methods.

    Requisites for procedure methods are described in ["REQUISITES FOR PROCEDURE METHODS"](#REQUISITES FOR PROCEDURE METHODS).

- register\_filter\_class

        # register filter methods of Validator::Procedural::Filter::Common
        $validator->register_filter_class('::Common');

        $validator->register_filter_class('MY::Own::Filter::Class');

        # restrict registering methods (like Perl's importer)
        $validator->register_filter_class('::Text', 'TRIM', 'LTRIM');

    Register filter methods from specified module.
    (Modules will be loaded automatically.)

- register\_rule\_class

        # register rule methods of Validator::Procedural::Rule::Common
        $validator->register_rule_class('::Common');

        $validator->register_rule_class('MY::Own::Rule::Class');

        # restrict registering methods
        $validator->register_rule_class('::Number', 'BIG', 'SMALL');

    Register rule methods from specified module.
    (Modules will be loaded automatically.)

- register\_procedure\_class

        # register procedure methods of Validator::Procedural::Procedure::Common
        $validator->register_procedure_class('::Common');

        $validator->register_procedure_class('MY::Own::Procedure::Class');

        # restrict registering methods
        $validator->register_procedure_class('::Text', 'address', 'telephone');

    Registers procedure methods from specified module.
    (Modules will be loaded automatically.)

- register\_formatter

        $validator->register_formatter( $formatter_instance );

    Registers error message formatter object.
    Requisites for message formatter class is described in ["REQUISITES FOR MESSAGE FORMATTER CLASS"](#REQUISITES FOR MESSAGE FORMATTER CLASS).

    If formatter is not specified, an instance of [Validator::Procedural::Formatter::Minimal](https://metacpan.org/pod/Validator::Procedural::Formatter::Minimal) will be used as formatter on the first generation of error messages.

- results

        my $results = $validor->results;

    Retrieves results object (instance of `Validator::Procedural::Results`).

    Available methods are described in ["METHODS OF Validator::Procedural::Results"](#METHODS OF Validator::Procedural::Results).

- process

        my $result = $validor->process('field_name', 'PROCEDURE');
        my $result = $validor->process('field_name', sub { ... });

    Executes validation procedure.

    Procedures are provided in procedure names or in subroutine references.

        my $result = $validor->process('field_name', 'PROCEDURE', $value1, $value2, ...);
        my $result = $validor->process('field_name', sub { ... }, $value1, $value2, ...);

    If you specify values after procedure for arguments, they will be used as initial values for procedure.

# METHODS OF Validator::Procedural::Results

- value

        my $val  = $validator->valud('field_name');     # retrieve first value
        my @vals = $validator->valud('field_name');

        $validator->value('field_name', $value);
        $validator->value('field_name', $multi_value1, $multi_value2, ...);

    Gets and sets field value.

    On retrieval, first value of multiple values are returned in scalar context.
    In array context all of values are returned.

- values

        my $values = $results->values();  # => instance of Hash::MultiValue
        my %values = $results->values();

    Gets all values for all fields.

    In scalar context, [Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue) will be returned.

    In array context, field names and values pairs are returned.
    Order of fields corresponds to order of processing.

- success

    Returns true if result has no error.

- has\_error

    Returns true if result has error.

- valid\_fields

    Returns names of valid fields.

- invalid\_fields

        my @fields = $results->invalid_fields();
        my @fields = $results->invalid_fields('ERROR_CODE1', 'ERROR_CODE2', ...);
        my @fields = $results->invalid_fields(sub { ... });

    Returns names of invalid fields.

    When error codes are specified, only fields which have specified error codes are returned.

    Error code filtering methods can also be supplied as arguments.

- errors

        my %errors = $results->errors();
        my $errors = $results->errors();
        # => +{
        #       field1 => [ 'ERROR_CODE1' ],
        #       field2 => [ 'ERROR_CODE1', 'ERROR_CODE2' ],
        #       ...
        #    }

    Returns field names and error codes mappings.

    In scalar context, hash-ref will be returned.
    In array context, order of fields corresponds to order of processing.

- error

        my @errors = $results->error('field_name');

    Returns error codes for specified field.

- valid

    Returns true when specified field is valid.

- invalid

    Returns true when specified field is invalid.

- error\_messages

        my @messages = $results->error_messages();

    Gets error messages in array.

    Error messages will be formatted by `formatter()` instance.

- error\_message

        my @messages = $results->error_message('field_name');

    Gets error messages for specified field in array.

# INTERNAL API METHODS

Following methods are considered as somewhat of internal APIs.
But these are convenient when you want to set validation state from the outside of validation procedures (You already have faced such a situation I believe), so usage of these are not restricted.

For further information for what APIs do, please refer to ["METHODS" in Validator::Procedural::Field](https://metacpan.org/pod/Validator::Procedural::Field#METHODS).

- apply\_filter

        $validator->apply_filter('field_name', 'FILTER');
        $validator->apply_filter('field_name', 'FILTER', %options);
- check

        $validator->check('field_name', 'RULE');
        $validator->check('field_name', 'RULE', %options);

# INTERNAL API METHODS OF Validator::Procedural::Results

- add\_error

        $results->add_error('field_name', 'ERROR_CODE', 'ERROR_CODE', ...);
- clear\_errors

        $results->clear_errors('field_name');
        $results->clear_errors();             # clears all errors
- set\_errors

        $results->set_errors('field_name', 'ERROR_CODE', 'ERROR_CODE', ...);
        $results->set_errors('field_name');   # same as clear_errors('field_name');

# REQUISITES FOR FILTER METHODS

    $validator->register_filter(
        TRIM => sub {
            s{ (?: \A \s+ | \s+ \z ) }{}gxmso;
            $_;     # should return filtered value
        },
    );

Filter methods accept original value from `$_` and should return filtered values.

You can receive original value from method arguments, following options specified in `apply_filter()` method.

    $validator->register_filter(
        REPEAT => sub {
            my ($value, $option) = @_;
            return $value x $option->{times};
        },
    );

# REQUISITES FOR RULE METHODS

    $validator->register_rule(
        EMAIL => sub {
            unless (m{\A \w+ @ \w+ (?: \. \w+ )+ \z}xmso) {
                return 'INVALID';   # error code for errors
            }

            return;                 # (undef) for OK
        },
    );

Filter methods accept single value from `$_` and should return error codes (yes you can return multiple error codes), or return undef for success.

If you want to check multiple values supplied, you can capture from method arguments, following options specified in `check()` method.

    $validator->register_rule(
        CONTAINS => sub {
            my $option = pop @_;
            my (@vals) = @_;

            unless (grep { $_ eq $option->{target} } @vals) {
                return 'ABSENT';
            }

            return;
        },
    );



# REQUISITES FOR PROCEDURE METHODS

    $validator->register_procedure(
        datetime => sub {
            my ($field) = @_;

            # apply filters
            $field->apply_filter('TRIM');

            # apply rules
            return unless $field->check('EXISTS');

            # filter value by hand
            my $val = $field->value();
            $field->value($val . ' +0000');

            # check value manually
            eval {
                require Time::Piece;
                Time::Piece->strptime($field->value, '%Y-%m-%d %z');
            };
            if ($@) {
                $field->add_error('INVALID_DATE');
                return;
            }
        }
    );

Requisites for procedure methods are quite simple.
Do what you want.

[Validator::Procedural::Field](https://metacpan.org/pod/Validator::Procedural::Field) parameter is supplied as argument.
Then you may filter things, and you may check constraints.

Returned value will not be used (but will reflect into result of `process()` method).

Especially when procedure is specified as argument for `process()`, you can conjunct multiple parameters into a field.
(Of course in registered procedures, you can set value explicity, but it seems useless.)

    $validator->process('tel',
        sub {
            my ($field) = @_;

            $field->value( sprintf '%s-%s-%s', $param->{tel1}, $param->{tel2}, $param->{tel3} );

            $field->apply_filter('TOUPPER');

            return unless $field->check('TEL');
        }
    );

# REQUISITES FOR MESSAGE FORMATTER CLASS

    package My::Message::Formatter;

    sub new { ... }

    sub format {
        my ($self, $field_name, @error_codes) = @_;

        my @msgs = map { sprintf '%s is %s.', $field_name, $_ } @error_codes;
        return @msgs;
    }

Message formatter class must have `format()` method, which accepts field name and error codes as arguments. It should return error message(s).

# FULL EXAMPLES

    use Validator::Procedural;

    # create validator prototype with given filters / rules.
    my $prot = Validator::Procedural::Prototype->new(
        filters => {
            UCFIRST => sub { ucfirst },
        },
        rules => {
            NUMERIC => sub { /^\d+$/ || 'INVALID' },
        },
    );

    # filter plugins can be applied to validators (and to prototypes).
    Validator::Procedural::Filter::Common->register_to($prot, 'TRIM', 'LTRIM');
    # also rule plugins can be
    Validator::Procedural::Rule::Common->register_to($prot);

    # filter class registration can be called from validators (and to prototypes).
    # package begins with '::' is recognized as belonging to 'Validator::Procedural::Filter::' namespace.
    $prot->register_filter_class('::Japanese', 'HAN2ZEN', 'ZEN2HAN');
    $prot->register_filter_class('MY::Own::Filter');    # import all filter
    # also for rule class registration
    # package begins with '::' is recognized as belonging to 'Validator::Procedural::Rule::' namespace.
    $prot->register_rule_class('::Date');               # import all checker
    $prot->register_rule_class('MY::Own::Rule', 'MYRULE');

    # you can register filters (and rules) after instantiation of prototype
    $prot->register_filter(
        TRIM => sub { s{ (?: \A \s+ | \s+ \z ) }{}gxmso; $_ },
    );

    $prot->register_rule(
        EMAIL => sub {
            # Of course not precise for email address, but just example.
            unless (m{\A \w+ @ \w+ (?: \. \w+ )+ \z}xmso) {
                return 'INVALID';   # error codes for errors
            }

            return;                 # (undef) for OK
        },
    );

    # can register common filtering and checking procedure (but not required)
    $prot->register_procedure(
        name => sub {
            my ($field) = @_;

            # apply filters
            $field->apply_filter('TRIM');

            # apply rules
            return unless $field->check('EXISTS');
        }
    );

    # register error message formatter (default is Validator::Procedural::Formatter::Minimal)
    $prot->register_formatter(Validator::Procedural::Formatter::Minimal->new());

    # now create validator (with state) from prototype
    my $validator = $prot->create_validator();

    # you can register filters (and checkers) into validators
    $validator->register_filter(
        LTRIM => sub { s{ \A \s+ }{}xmso; $_ },
    );

    # process validation for field 'bar' by custom procedure
    $validator->process('bar', sub {
        my ($field) = @_;

        # set value
        $field->value($req->param('bar'));

        # apply filters
        $field->apply_filter('TRIM');

        # apply rules
        return unless $field->check('EXISTS');

        # filter value by hand
        my $val = $field->value;
        $val =~ s/-//g;
        $field->value($val);

        # check value manually
        unless ($field->value =~ /^\d{7}/) {
            $field->add_error('INVALID');
        }
    });

    # can apply registered procedure with given value
    $validator->process('foo', 'name', $req->param('foo'));



    # retrieve validation result
    my $results = $validator->results;

    $results->success();      # => TRUE or FALSE
    $results->has_error();    # => ! success()

    # retrieve fields and errors mapping
    $results->errors();       # return errors errors in Array or Hash-ref (for scalar context)
    # => (
    #     foo => [ 'MISSING', 'INVALID_DATE' ],
    # )

    $results->invalid_fields();
    # => ( 'foo', 'bar' )

    # can filter fields that has given error code
    $results->invalid_fields('MISSING');
    # => ( 'foo', 'bar' )

    # error code filtering rule can be supplied with subroutine
    $results->invalid_fields(sub { grep { $_ eq 'MISSING' } @_ });
    # => ( 'foo', 'bar' )

    $results->valid('foo');       # => TRUE of FALSE
    $results->invalid('foo');     # => ! valid()

    # retrieve error codes (or empty for valid field)
    $results->error('foo');       # return errors for specified field in Array
    # => ( 'MISSING', 'INVALID_DATE' )

    # clear all errors
    $results->clear_errors();
    # clear errors for specified fields
    $results->clear_errors('foo');

    # append error (manually)
    $results->add_error('foo', 'MISSING');

    # retrieve filtered value for specified field
    $results->value('foo');
    # retrieve all values filtered
    $results->values();   # return values in Array or Hash::MultiValue (for scalar context)
    # => (
    #     foo => [ 'val1', 'val2' ],
    #     var => [ 'val1' ],            # always in Array-ref for single value
    # )

    # retrieve error messages for all fields
    $results->error_messages();
    # retrieve error message(s) for given field
    $results->error_message('foo');

# LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

ITO Nobuaki <dayflower@cpan.org>
