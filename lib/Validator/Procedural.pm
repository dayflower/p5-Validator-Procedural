package Validator::Procedural;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

package Validator::Procedural::_RegistryMixin;

use Carp;

sub register_filter {
    my ($self, @args) = @_;
    while (my ($name, $filter) = splice @args, 0, 2) {
        $self->{filters}->{$name} = $filter;
    }
    return $self;
}

sub register_checker {
    my ($self, @args) = @_;
    while (my ($name, $checker) = splice @args, 0, 2) {
        $self->{checker}->{$name} = $checker;
    }
    return $self;
}

sub register_procedure {
    my ($self, @args) = @_;
    while (my ($name, $procedure) = splice @args, 0, 2) {
        $self->{procedure}->{$name} = $procedure;
    }
    return $self;
}

foreach my $prop (qw( filter checker procedure )) {
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

        unless (eval "require $package" && ! $@) {
            croak "require $package failed: $@";
        }

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
        checkers   => {},
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
        checkers   => { %{$self->{checkers}}   },
        procedures => { %{$self->{procedures}} },
        formatter  => $self->{formatter},
    );
}

package Validator::Procedural;

use Carp;
use List::Util qw( first );

our @ISA = qw( Validator::Procedural::_RegistryMixin );

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        filters    => {},
        checkers   => {},
        procedures => {},

        value        => {},
        value_fields => [],
        error        => {},
        error_fields => [],

        %args,
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

sub process {
    my ($self, $field, $procedure, @vals) = @_;

    if (@vals) {
        $self->value($field, @vals);
    }

    if (! ref $procedure) {
        my $meth = $self->{procedures}->{$procedure};
        unless ($meth) {
            croak "Undefined procedure: '$procedure'";
        }
        $procedure = $meth;
    }

    &$procedure($self->field($field));

    return $self;
}

sub field {
    my ($self, $field_name) = @_;
    return Validator::Procedural::Field->new($self, $field_name);
}

sub value {
    my ($self, $field) = splice @_, 0, 2;

    if (@_) {
        if (@_ == 1 && ! defined $_[0]) {
            delete $self->{value}->{$field};
            @{$self->{value_fields}} = grep { $_ ne $field } @{$self->{error_fields}};
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
    return wantarray ? @values : +{ @values };
}

sub apply_filter {
    my ($self, $field, $filter, %options) = @_;

    my @vals = $self->value($field);

    my $meth = $filter;
    if (! ref $meth) {
        $meth = $self->{filters}->{$filter};
        unless ($meth) {
            croak "Undefined filter: '$filter'";
        }
    }

    @vals = map { &$meth($_, \%options) } @vals;

    $self->value($field, @vals);

    return @vals;
}

sub check {
    my ($self, $field, $checker, %options) = @_;

    my @vals = $self->value($field);

    my $meth = $checker;
    if (! ref $meth) {
        $meth = $self->{checkers}->{$checker};
        unless ($meth) {
            croak "Undefined checker '$checker'";
        }
    }

    my @error_codes = do {
        local $_ = $vals[0];
        grep { defined $_ && $_ ne "" } &$meth(@vals, \%options);
    };
    if (@error_codes) {
        $self->add_error($field, @error_codes);
    }

    return @error_codes == 0;
}

sub success {
    my ($self) = @_;
    return ! $self->has_error();
}

sub has_error {
    my ($self) = @_;
    return $self->{error_fields} > 0;
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

sub valid {
    my ($self, $field) = @_;

    return ! $self->invalid($field);
}

sub invalid {
    my ($self, $field) = @_;

    return exists $self->{error}->{$field};
}

sub clear_errors {
    my ($self, $field) = @_;

    if (defined $field) {
        delete $self->{error}->{$field};
        @{$self->{error_fields}} = grep { $_ ne $field }
                                        @{$self->{error_fields}};
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

foreach my $method (qw( value apply_filter check
                     error clear_errors set_error add_error )) {
    my $sub = sub {
        my $self = shift;
        return $self->{validator}->$method($self->{label}, @_);
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

=head1 DESCRIPTION

Validator::Procedural is yet another validation module.

=head1 MOTIVATION FOR YET ANOTHER VALIDATION MODULE

There are so many validation modules on CPAN.  Why yet another one?

Some of modules provide good-looking features with simple configuration, but when I used those modules for compositing several fields and filtering fields (and for condition of some fields depending on other field), some were not able to handle such situation, some required custom handler.

So I focused on following points for design this module.

=over 4

=item To provide compact but sufficient container for validation result

=item To provide filtering mechanism and functionality to retrieve filtered parameters

=item To depend on other modules as least as possible (complex validators and filters depending on other modules heavyly will be supplied as dependent plugin distributions)

=back

This module is NOT all-in-one validation product.  This module DOES NOT provide easy configuration.  But you have to implement validation procedure with Perl code, so on such a complex condition described above, you can make codes straightforwardly, easy to understand.

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>daydream.trippers@gmail.comE<gt>

=cut

