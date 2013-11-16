package Validator::Procedural;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

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

sub register_formatter {
    my ($self, $formatter) = @_;
    $self->{formatter} = $formatter;
    return $self;
}

sub register_filter_class {
    die;
}

sub register_checker_class {
    die;
}

sub register_procedure_class {
    die;
}

sub create_validator {
    my $self = shift;

    return Validator::Procedural::Validator->new(
        filters    => { %{$self->{filters}}    },
        checkers   => { %{$self->{filters}}    },
        procedures => { %{$self->{procedures}} },
        formatter  => $self->{formatter},
    );
}

package Validator::Procedural::Validator;

use Carp;

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
        require Validator::Procedural::Formatter::Simple;
        $self->{formatter} = Validator::Procedural::Formatter::Simple->new();
    }

    return $self->{formatter};
}

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

sub register_formatter {
    my ($self, $formatter) = @_;
    $self->formatter($formatter);
    return $self;
}

sub register_filter_class {
    die;
}

sub register_checker_class {
    die;
}

sub register_procedure_class {
    die;
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

sub success {
    my ($self) = @_;
    return ! $self->has_error();
}

sub has_error {
    my ($self) = @_;
    my @has_error = grep { @{$self->{error}->{$_}} > 0 }
                         @{$self->{error_fields}};
    return @has_error > 0;
}

sub errors {
    my ($self) = @_;

    my @errors = map { $_ => $self->{error}->{$_} } @{$self->{error_fields}};
    return wantarray ? @errors : +{ @errors };
}

sub error {
    my ($self, $field) = splice @_, 0, 2;
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

    delete $self->{error}->{$field};
    @{$self->{error_fields}} = grep { $_ ne $field } @{$self->{error_fields}};

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

        $self->{errors}->{$field} = [];
    }

    push @{$self->{error}->{$field}}, @_;

    return $self;
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

foreach my $key (qw( value apply_filters check check_all
                     error clear_errors set_error add_error )) {
    my $sub = sub {
        my $self = shift;
        return $self->{validator}->$key($self->{label}, @_);
    };

    no strict 'refs';
    *{__PACKAGE__ . '..' . $key} = $sub;
}

1;
__END__

=encoding utf-8

=head1 NAME

Validator::Procedural - Procedural validator

=head1 SYNOPSIS

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

