use strict;
use Test::More;
use Validator::Procedural;

subtest "single value" => sub {
    my $mech = Validator::Procedural->new();
    my $vtor = $mech->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
        $field->value(1);
    });

    is $vtor->value('foo'), 1;
};

subtest "multiple values" => sub {
    my $mech = Validator::Procedural->new();
    my $vtor = $mech->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
        $field->value(1, 1, 2, 3, 5);
    });

    is $vtor->value('foo'), 1;
    is_deeply [ $vtor->value('foo') ], [ 1, 1, 2, 3, 5 ];
};

subtest "value via process" => sub {
    my $mech = Validator::Procedural->new();
    my $vtor = $mech->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
    }, 1, 1, 2, 3, 5);

    is $vtor->value('foo'), 1;
    is_deeply [ $vtor->value('foo') ], [ 1, 1, 2, 3, 5 ];
};

subtest "add_error" => sub {
    my $mech = Validator::Procedural->new();
    my $vtor = $mech->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
        $field->add_error('BAR');
        $field->add_error('BAZ');
    });

    is_deeply $vtor->error('foo'), [ 'BAR', 'BAZ' ];
};

done_testing;
