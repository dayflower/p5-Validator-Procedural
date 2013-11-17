package Validator::Procedural::Formatter::Minimal;
use 5.008005;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $fields = delete $args{fields} || {};
    my $errors = delete $args{errors} || {};

    my $self = bless {
        fields => +{
            %$fields,
        },
        errors => +{
            MISSING => '[_1] is missing',
            INVALID => '[_1] is invalid',

            %$errors,
        },
    }, $class;

    return $self;
}

sub format {
    my ($self, $field, @error_codes) = @_;
    return unless @error_codes;

    my $field_name = $self->field_name($field);

    return map { s/\Q[_1]\E/$field_name/g; $_ }
           map { $self->error_template($_) }
               @error_codes;
}

sub error_template {
    my ($self, $error_code) = @_;

    unless (defined $self->{errors}->{$error_code}) {
        $self->{errors}->{$error_code} = $self->error_template_fallback($error_code);
    }

    return $self->{errors}->{$error_code};
}

sub error_template_fallback {
    my ($self, $error_code) = @_;
    return $self->{errors}->{INVALID};
}

sub field_name {
    my ($self, $field) = @_;

    unless (defined $self->{fields}->{$field}) {
        $self->{fields}->{$field} = $self->field_name_fallback($field);
    }

    return $self->{fields}->{$field};
}

sub field_name_fallback {
    my ($self, $field) = @_;

    return ucfirst lc $field;
}

1;
__END__

=encoding utf-8

=head1 NAME

Validator::Procedural::Formatter::Minimal - ...

=head1 SYNOPSIS

    use Validator::Procedural;
    use Validator::Procedural::Formatter::Minimal;

    my $formatter = Validator::Procedural::Formatter::Minimal->new(
        fields => {
            foo => 'Foo',
        },
        errors => {
            MISSING => '[_1] is missing',
            INVALID => '[_1] is invalid',
        },
    );

    my $prot = Validator::Procedural::Prototype->new(
        formatter => $formatter,
    );

    my $validator = $prot->create_validator();

=head1 DESCRIPTION

Validator::Procedural::Formatter::Minimal is ...

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>daydream.trippers@gmail.comE<gt>

=cut

