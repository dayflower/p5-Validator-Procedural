package Validator::Procedural;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

package Validator::Procedural::_RegistryMixin;

use Carp;
use Module::Load ();

sub register_filter {
    my ($self, @args) = @_;
    while (my ($name, $filter) = splice @args, 0, 2) {
        $self->{filters}->{$name} = $filter;
    }
    return $self;
}

sub register_rule {
    my ($self, @args) = @_;
    while (my ($name, $rule) = splice @args, 0, 2) {
        $self->{rules}->{$name} = $rule;
    }
    return $self;
}

sub register_procedure {
    my ($self, @args) = @_;
    while (my ($name, $procedure) = splice @args, 0, 2) {
        $self->{procedures}->{$name} = $procedure;
    }
    return $self;
}

foreach my $prop (qw( filter rule procedure )) {
    my $prefix = ucfirst $prop;
    my $sub = sub {
        my ($self, $package) = splice @_, 0, 2;

        if ($package =~ s/^\:://) {
            # plugin namespace
            $package = "Validator::Procedural::$prefix::$package";
        }
        else {
            # full spec package name
        }

        Module::Load::load($package);

        $package->register_to($self, @_);

        return $self;
    };

    my $func = sprintf '%s::register_%s_class', __PACKAGE__, $prop;

    no strict 'refs';
    *{$func} = $sub;
}

package Validator::Procedural::Prototype;

our $VERSION = $Validator::Procedural::VERSION;

our @ISA = qw( Validator::Procedural::_RegistryMixin );

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        filters    => {},
        rules      => {},
        procedures => {},

        %args,
    }, $class;
    return $self;
}

sub register_formatter {
    my ($self, $formatter) = @_;
    $self->{formatter} = $formatter;
    return $self;
}

sub create_validator {
    my $self = shift;

    return Validator::Procedural->new(
        filters    => { %{$self->{filters}}    },
        rules      => { %{$self->{rules}}      },
        procedures => { %{$self->{procedures}} },
        formatter  => $self->{formatter},
    );
}

package Validator::Procedural;

use Carp;
use List::Util qw( first );
use Hash::MultiValue;

our @ISA = qw( Validator::Procedural::_RegistryMixin );

sub new {
    my ($class, %args) = @_;
    my $formatter = delete $args{formatter};

    my $self = bless {
        filters    => {},
        rules      => {},
        procedures => {},

        %args,
    }, $class;

    $self->{results} = Validator::Procedural::Results->new();

    if (defined $formatter) {
        $self->register_formatter($formatter);
    }

    return $self;
}

sub results { $_[0]->{results} }

sub formatter {
    my $self = shift;

    if (@_) {
        $self->register_formatter(@_);
    }

    return $self->results->formatter;
}

sub register_formatter {
    my ($self, $formatter) = @_;
    $self->results->formatter($formatter);
    return $self;
}

sub process {
    my ($self, $field, $procedure, @vals) = @_;

    if (@vals) {
        $self->results->value($field, @vals);
    }

    if (! ref $procedure) {
        my $meth = $self->{procedures}->{$procedure};
        unless ($meth) {
            croak "Undefined procedure: '$procedure'";
        }
        $procedure = $meth;
    }

    return &$procedure($self->field($field));
}

sub field {
    my ($self, $field_name) = @_;
    return Validator::Procedural::Field->new($self, $field_name);
}

sub remove_field {
    my ($self, @field_names) = @_;

    foreach my $field_name (@field_names) {
        $self->results->value($field_name, undef);
        $self->results->clear_errors($field_name);
    }

    return $self;
}

sub apply_filter {
    my ($self, $field, $filter, %options) = @_;

    my @vals = $self->results->value($field);

    my $meth = $filter;
    if (! ref $meth) {
        $meth = $self->{filters}->{$filter};
        unless ($meth) {
            croak "Undefined filter: '$filter'";
        }
    }

    @vals = map { &$meth($_, \%options) } @vals;

    $self->results->value($field, @vals);

    return @vals;
}

sub check {
    my ($self, $field, $rule, %options) = @_;

    my @vals = $self->results->value($field);

    my $meth = $rule;
    if (! ref $meth) {
        $meth = $self->{rules}->{$rule};
        unless ($meth) {
            croak "Undefined rule '$rule'";
        }
    }

    my @error_codes = do {
        local $_ = $vals[0];
        grep { defined $_ && $_ ne "" } &$meth(@vals, \%options);
    };
    if (@error_codes) {
        $self->results->add_error($field, @error_codes);
    }

    return @error_codes == 0;
}

package Validator::Procedural::Results;

sub new {
    my ($class) = @_;
    my $self = bless {
        value        => {},
        value_fields => [],
        error        => {},
        error_fields => [],
    }, $class;
    return $self;
}

sub formatter {
    my $self = shift;

    if (@_) {
        $self->{formatter} = shift;
    }

    unless ($self->{formatter}) {
        require Validator::Procedural::Formatter::Minimal;
        $self->{formatter} = Validator::Procedural::Formatter::Minimal->new();
    }

    return $self->{formatter};
}

sub value {
    my ($self, $field) = splice @_, 0, 2;

    if (@_) {
        if (@_ == 1 && ! defined $_[0]) {
            delete $self->{value}->{$field};
            @{$self->{value_fields}} = grep { $_ ne $field } @{$self->{value_fields}};
        }
        else {
            if (! exists $self->{value}->{$field}) {
                push @{$self->{value_fields}}, $field;
            }

            $self->{value}->{$field} = [ @_ ];
        }
    }

    return unless exists $self->{value}->{$field};
    my $vals = $self->{value}->{$field};
    return unless defined $vals;

    return wantarray ? @$vals : $vals->[0];
}

sub values {
    my ($self) = @_;

    my @values = map { $_ => $self->{value}->{$_} } @{$self->{value_fields}};
    return wantarray ? @values : Hash::MultiValue->from_mixed(@values);
}

sub success {
    my ($self) = @_;
    return ! $self->has_error();
}

sub has_error {
    my ($self) = @_;
    return @{$self->{error_fields}} > 0;
}

sub valid_fields {
    my ($self) = @_;

    my @fields = grep { ! exists $self->{error}->{$_} }
                      @{$self->{value_fields}};
    return @fields;
}

sub invalid_fields {
    my $self = shift;

    my @fields = @{$self->{error_fields}};

    my @crits = map { ref $_ ? $_ : _gen_invalid_matcher($_) } @_;
    if (@crits) {
        my $e = $self->{error};
        @fields = grep { my $f = $_; first { &$_(@{$e->{$f}}) } @crits }
                       @fields;
    }

    return @fields;
}

sub _gen_invalid_matcher {
    my ($error_code) = @_;
    return sub { first { $_ eq $error_code } @_ };
}

sub valid {
    my ($self, $field) = @_;

    return ! $self->invalid($field);
}

sub invalid {
    my ($self, $field) = @_;

    return exists $self->{error}->{$field};
}

sub errors {
    my ($self) = @_;

    my @errors = map { $_ => $self->{error}->{$_} } @{$self->{error_fields}};
    return wantarray ? @errors : +{ @errors };
}

sub error {
    my ($self, $field) = splice @_, 0, 2;

    return unless exists $self->{error}->{$field};

    my @errors = @{$self->{error}->{$field}};

    return @errors;
}

sub clear_errors {
    my ($self, $field) = @_;

    if (defined $field) {
        delete $self->{error}->{$field};
        @{$self->{error_fields}} = grep { $_ ne $field } @{$self->{error_fields}};
    }
    else {
        $self->{error} = {};
        $self->{error_fields} = [];
    }

    return $self;
}

sub set_errors {
    my ($self, $field) = splice @_, 0, 2;

    if (@_) {
        if (! exists $self->{error}->{$field}) {
            push @{$self->{error_fields}}, $field;
        }

        $self->{error}->{$field} = [ @_ ];
    }
    else {
        $self->clear_errors($field);
    }

    return $self;
}

sub add_error {
    my ($self, $field) = splice @_, 0, 2;

    if (! exists $self->{error}->{$field}) {
        push @{$self->{error_fields}}, $field;

        $self->{error}->{$field} = [];
    }

    push @{$self->{error}->{$field}}, @_;

    return $self;
}

sub error_messages {
    my ($self) = @_;

    my @messages = map { $self->error_message($_) } @{$self->{error_fields}};
    return @messages;
}

sub error_message {
    my ($self, $field) = @_;

    return $self->formatter->format($field, $self->error($field));
}

package Validator::Procedural::Field;

sub new {
    my ($class, $validator, $label) = @_;
    my $self = bless {
        validator => $validator,
        label     => $label,
    }, $class;
    return $self;
}

sub label { $_[0]->{label} }

foreach my $method (qw( apply_filter check )) {
    my $sub = sub {
        my $self = shift;
        return $self->{validator}->$method($self->{label}, @_);
    };

    my $func = sprintf '%s::%s', __PACKAGE__, $method;

    no strict 'refs';
    *{$func} = $sub;
}

foreach my $method (qw( value error clear_errors set_errors add_error )) {
    my $sub = sub {
        my $self = shift;
        return $self->{validator}->results->$method($self->{label}, @_);
    };

    my $func = sprintf '%s::%s', __PACKAGE__, $method;

    no strict 'refs';
    *{$func} = $sub;
}

1;
__END__

=encoding utf-8

=head1 NAME

Validator::Procedural - Procedural validator

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Validator::Procedural is yet another validation module.

THIS MODULE IS CURRENTLY ON WORKING DRAFT PHASE.  API MAY CHANGE.

=head1 MOTIVATION FOR YET ANOTHER VALIDATION MODULE

There are so many validation modules on CPAN.  Why yet another one?

Some of such modules provide good-looking features with simple configuration. But when I used those modules for compositing several fields and filtering fields (and for condition of some fields depending on other field), some were not able to handle such situation, some required custom handler.

So I focused on following points for design this module.

=over 4

=item To provide compact but sufficient container for validation results

=item To provide filtering mechanism and functionality to retrieve filtered parameters

=item To depend on other modules as least as possible (complex validators and filters depending on other modules heavyly should be supplied as dependent plugin distributions)

=item To make error message formatter independent of validator

=back

This module is NOT all-in-one validation product.  This module DOES NOT provide easy configuration.  But you have to implement validation procedure with Perl code, so on such a complex condition described above, you can write codes straightforwardly, easy to understand.

=head1 METHODS

=over 4

=item register_filter

    $validator->register_filter(
        FOO => sub { ... },
        BAR => sub { ... },
        ...
    );

Registers filter methods.

Requisites for filter methods are described in L<"REQUISITES FOR FILTER METHODS">.

=item register_rule

    $validator->register_rule(
        FOO => sub { ... },
        BAR => sub { ... },
        ...
    );

Registers rule methods.

Requisites for rule methods are described in L<"REQUISITES FOR RULE METHODS">.

=item register_procedure

    $validator->register_procedure(
        foo => sub { ... },
        bar => sub { ... },
        ...
    );

Registers procedure methods.

Requisites for procedure methods are described in L<"REQUISITES FOR PROCEDURE METHODS">.

=item register_filter_class

    # register filter methods of Validator::Procedural::Filter::Common
    $validator->register_filter_class('::Common');

    $validator->register_filter_class('MY::Own::Filter::Class');

    # restrict registering methods (like Perl's importer)
    $validator->register_filter_class('::Text', 'TRIM', 'LTRIM');

Register filter methods from specified module.
(Modules will be loaded automatically.)

=item register_rule_class

    # register rule methods of Validator::Procedural::Rule::Common
    $validator->register_rule_class('::Common');

    $validator->register_rule_class('MY::Own::Rule::Class');

    # restrict registering methods
    $validator->register_rule_class('::Number', 'BIG', 'SMALL');

Register rule methods from specified module.
(Modules will be loaded automatically.)

=item register_procedure_class

    # register procedure methods of Validator::Procedural::Procedure::Common
    $validator->register_procedure_class('::Common');

    $validator->register_procedure_class('MY::Own::Procedure::Class');

    # restrict registering methods
    $validator->register_procedure_class('::Text', 'address', 'telephone');

Registers procedure methods from specified module.
(Modules will be loaded automatically.)

=item register_formatter

    $validator->register_formatter( $formatter_instance );

Registers error message formatter object.
Requisites for message formatter class is described in L<"REQUISITES FOR MESSAGE FORMATTER CLASS">.

If formatter is not specified, an instance of L<Validator::Procedural::Formatter::Minimal> will be used as formatter on the first generation of error messages.

=item results

    my $results = $validor->results;

Retrieves results object (instance of C<Validator::Procedural::Results>).

Available methods are described in L<"METHODS OF Validator::Procedural::Results">.

=item process

    my $result = $validor->process('field_name', 'PROCEDURE');
    my $result = $validor->process('field_name', sub { ... });

Executes validation procedure.

Procedures are provided in procedure names or in subroutine references.

    my $result = $validor->process('field_name', 'PROCEDURE', $value1, $value2, ...);
    my $result = $validor->process('field_name', sub { ... }, $value1, $value2, ...);

If you specify values after procedure for arguments, they will be used as initial values for procedure.

=back

=head1 METHODS OF Validator::Procedural::Results

=over 4

=item value

    my $val  = $validator->valud('field_name');     # retrieve first value
    my @vals = $validator->valud('field_name');

    $validator->value('field_name', $value);
    $validator->value('field_name', $multi_value1, $multi_value2, ...);

Gets and sets field value.

On retrieval, first value of multiple values are returned in scalar context.
In array context all of values are returned.

=item values

    my $values = $results->values();  # => instance of Hash::MultiValue
    my %values = $results->values();

Gets all values for all fields.

In scalar context, L<Hash::MultiValue> will be returned.

In array context, field names and values pairs are returned.
Order of fields corresponds to order of processing.

=item success

Returns true if result has no error.

=item has_error

Returns true if result has error.

=item valid_fields

Returns names of valid fields.

=item invalid_fields

    my @fields = $results->invalid_fields();
    my @fields = $results->invalid_fields('ERROR_CODE1', 'ERROR_CODE2', ...);
    my @fields = $results->invalid_fields(sub { ... });

Returns names of invalid fields.

When error codes are specified, only fields which have specified error codes are returned.

Error code filtering methods can also be supplied as arguments.

=item errors

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

=item error

    my @errors = $results->error('field_name');

Returns error codes for specified field.

=item valid

Returns true when specified field is valid.

=item invalid

Returns true when specified field is invalid.

=item error_messages

    my @messages = $results->error_messages();

Gets error messages in array.

Error messages will be formatted by C<formatter()> instance.

=item error_message

    my @messages = $results->error_message('field_name');

Gets error messages for specified field in array.

=back

=head1 INTERNAL API METHODS

Following methods are considered as somewhat of internal APIs.
But these are convenient when you want to set validation state from the outside of validation procedures (You already have faced such a situation I believe), so usage of these are not restricted.

For further information for what APIs do, please refer to L<Validator::Procedural::Field/"METHODS">.

=over 4

=item apply_filter

    $validator->apply_filter('field_name', 'FILTER');
    $validator->apply_filter('field_name', 'FILTER', %options);

=item check

    $validator->check('field_name', 'RULE');
    $validator->check('field_name', 'RULE', %options);

=back

=head1 INTERNAL API METHODS OF Validator::Procedural::Results

=over 4

=item add_error

    $results->add_error('field_name', 'ERROR_CODE', 'ERROR_CODE', ...);

=item clear_errors

    $results->clear_errors('field_name');
    $results->clear_errors();             # clears all errors

=item set_errors

    $results->set_errors('field_name', 'ERROR_CODE', 'ERROR_CODE', ...);
    $results->set_errors('field_name');   # same as clear_errors('field_name');

=back

=head1 REQUISITES FOR FILTER METHODS

    $validator->register_filter(
        TRIM => sub {
            s{ (?: \A \s+ | \s+ \z ) }{}gxmso;
            $_;     # should return filtered value
        },
    );

Filter methods accept original value from C<$_> and should return filtered values.

You can receive original value from method arguments, following options specified in C<apply_filter()> method.

    $validator->register_filter(
        REPEAT => sub {
            my ($value, $option) = @_;
            return $value x $option->{times};
        },
    );

=head1 REQUISITES FOR RULE METHODS

    $validator->register_rule(
        EMAIL => sub {
            unless (m{\A \w+ @ \w+ (?: \. \w+ )+ \z}xmso) {
                return 'INVALID';   # error code for errors
            }

            return;                 # (undef) for OK
        },
    );

Filter methods accept single value from C<$_> and should return error codes (yes you can return multiple error codes), or return undef for success.

If you want to check multiple values supplied, you can capture from method arguments, following options specified in C<check()> method.

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


=head1 REQUISITES FOR PROCEDURE METHODS

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

L<Validator::Procedural::Field> parameter is supplied as argument.
Then you may filter things, and you may check constraints.

Returned value will not be used (but will reflect into result of C<process()> method).

Especially when procedure is specified as argument for C<process()>, you can conjunct multiple parameters into a field.
(Of course in registered procedures, you can set value explicity, but it seems useless.)

    $validator->process('tel',
        sub {
            my ($field) = @_;

            $field->value( sprintf '%s-%s-%s', $param->{tel1}, $param->{tel2}, $param->{tel3} );

            $field->apply_filter('TOUPPER');

            return unless $field->check('TEL');
        }
    );

=head1 REQUISITES FOR MESSAGE FORMATTER CLASS

    package My::Message::Formatter;

    sub new { ... }

    sub format {
        my ($self, $field_name, @error_codes) = @_;

        my @msgs = map { sprintf '%s is %s.', $field_name, $_ } @error_codes;
        return @msgs;
    }

Message formatter class must have C<format()> method, which accepts field name and error codes as arguments. It should return error message(s).

=head1 FULL EXAMPLES

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

    # filter plugins can be applied to validator (prototypes).
    Validator::Procedural::Filter::Common->register_to($prot, 'TRIM', 'LTRIM');
    # also rule plugins can be
    Validator::Procedural::Rule::Common->register_to($prot);

    # filter class registration can be called from validator (prototypes).
    # package begins with '::' is recognized under 'Validator::Procedural::Filter::' namespace.
    $prot->register_filter_class('::Japanese', 'HAN2ZEN');
    $prot->register_filter_class('MY::Own::Filter');
    # also for rule class registration
    # package begins with '::' is recognized under 'Validator::Procedural::Rule::' namespace.
    $prot->register_rule_class('::Date');
    $prot->register_rule_class('MY::Own::Rule', 'MYRULE');

    # you can register filters (and rules) after instantiation of prototype
    $prot->register_filter(
        TRIM => sub { s{ (?: \A \s+ | \s+ \z ) }{}gxmso; $_ },
    );

    $prot->register_rule(
        EMAIL => sub {
            # Of course this is not precise for email address, but just example.
            unless (m{\A \w+ @ \w+ (?: \. \w+ )+ \z}xmso) {
                return 'INVALID';   # error code for errors
            }

            return;                 # (undef) for OK
        },
    );

    # can register common filtering and checking procedure (not required)
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

    # process for field 'bar' by custom procedure
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
    $validator->process('foo', 'DATETIME', $req->param('foo'));


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

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>dayflower@cpan.orgE<gt>

=cut

