use strict;
use Test::More;
use Validator::Procedural;

subtest "label" => sub {
    my $mech = Validator::Procedural->new();
    my $vtor = $mech->create_validator();

    my $res;
    $vtor->process('foo', sub {
        my ($field) = @_;
        $res = $field->label;
    });

    is $res, 'foo';
};

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

    is_deeply [ $vtor->error('foo') ], [ 'BAR', 'BAZ' ];
};

subtest "apply_filters" => sub {
    my $mech = Validator::Procedural->new(
        filters => {
            TRIM    => sub { s{(?: \A \s+ | \s+ \z)}{}gxmso; $_ },
            UCFIRST => sub { ucfirst },
        },
    );
    my $vtor = $mech->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
        $field->apply_filters('TRIM', sub { lc }, 'UCFIRST');
    }, ' HELLO WORLD ');

    is scalar $vtor->value('foo'), 'Hello world';
};

subtest "check" => sub {
    my $mech = Validator::Procedural->new(
        checkers => {
            OK1 => sub { return },
            OK2 => sub { return },
            OK3 => sub { return },
            NG1 => sub { return 'NG1' },
            NG2 => sub { return 'NG2' },
            NG3 => sub { return 'NG3' },
        },
    );
    my $vtor = $mech->create_validator();

    $vtor->process('single', sub {
        my ($field) = @_;
        $field->check(qw( OK1 NG1 OK2 NG2 OK3 NG3 ));
    });

    $vtor->process('all', sub {
        my ($field) = @_;
        $field->check_all(qw( OK1 NG1 OK2 NG2 OK3 NG3 ));
    });

    is_deeply [ $vtor->error('single') ], [qw( NG1 )];

    is_deeply [ $vtor->error('all') ], [qw( NG1 NG2 NG3 )];
};

done_testing;
