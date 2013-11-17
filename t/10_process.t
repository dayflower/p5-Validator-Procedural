use strict;
use Test::More;
use Test::Difflet qw( is_deeply );
use Validator::Procedural;
use Validator::Procedural::Formatter::Minimal;

subtest "label" => sub {
    my $prot = Validator::Procedural::Prototype->new();
    my $vtor = $prot->create_validator();

    my $res;
    $vtor->process('foo', sub {
        my ($field) = @_;
        $res = $field->label;
    });

    is $res, 'foo';
};

subtest "single value" => sub {
    my $prot = Validator::Procedural::Prototype->new();
    my $vtor = $prot->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
        $field->value(1);
    });

    is $vtor->value('foo'), 1;
};

subtest "multiple values" => sub {
    my $prot = Validator::Procedural::Prototype->new();
    my $vtor = $prot->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
        $field->value(1, 1, 2, 3, 5);
    });

    is $vtor->value('foo'), 1;
    is_deeply [ $vtor->value('foo') ], [ 1, 1, 2, 3, 5 ];
};

subtest "value via process" => sub {
    my $prot = Validator::Procedural::Prototype->new();
    my $vtor = $prot->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
    }, 1, 1, 2, 3, 5);

    is $vtor->value('foo'), 1;
    is_deeply [ $vtor->value('foo') ], [ 1, 1, 2, 3, 5 ];
};

subtest "add_error" => sub {
    my $prot = Validator::Procedural::Prototype->new();
    my $vtor = $prot->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
        $field->add_error('BAR');
        $field->add_error('BAZ');
    });

    is_deeply [ $vtor->error('foo') ], [ 'BAR', 'BAZ' ];
};

subtest "apply_filter" => sub {
    my $prot = Validator::Procedural::Prototype->new(
        filters => {
            TRIM    => sub { s{(?: \A \s+ | \s+ \z)}{}gxmso; $_ },
            UCFIRST => sub { ucfirst },
        },
    );
    my $vtor = $prot->create_validator();

    $vtor->process('foo', sub {
        my ($field) = @_;
        $field->apply_filter('TRIM');
        $field->apply_filter(sub { lc });
        $field->apply_filter('UCFIRST');
    }, ' HELLO WORLD ');

    is scalar $vtor->value('foo'), 'Hello world';
};

subtest "check" => sub {
    my $prot = Validator::Procedural::Prototype->new(
        checkers => {
            OK1 => sub { return },
            OK2 => sub { return },
            OK3 => sub { return },
            NG1 => sub { return 'NG1' },
            NG2 => sub { return 'NG2' },
            NG3 => sub { return 'NG3' },
        },
    );
    my $vtor = $prot->create_validator();

    $vtor->process('all', sub {
        my ($field) = @_;
        $field->check($_) for qw( OK1 NG1 OK2 NG2 OK3 NG3 );
    });

    is_deeply [ $vtor->error('all') ], [qw( NG1 NG2 NG3 )];
};

subtest "checker logic" => sub {
    my $prot = Validator::Procedural::Prototype->new(
        checkers => {
            UC  => sub { /[A-Z]/ && 'UC'  },
            LC  => sub { /[a-z]/ && 'LC'  },
            NUM => sub { /[0-9]/ && 'NUM' },
            SP  => sub { /\s/    && 'SP'  },
        },
        procedures => {
            ALL => sub {
                my ($field) = @_;
                $field->check($_) for qw( UC LC NUM SP );
            },
        },
    );
    my $vtor = $prot->create_validator();

    $vtor->clear_errors('val');
    $vtor->process('val', 'ALL', ' abc ');
    is_deeply [ $vtor->error('val') ], [qw( LC SP )];

    $vtor->clear_errors('val');
    $vtor->process('val', 'ALL', 'Abc');
    is_deeply [ $vtor->error('val') ], [qw( UC LC )];

    $vtor->clear_errors('val');
    $vtor->process('val', 'ALL', '123 456');
    is_deeply [ $vtor->error('val') ], [qw( NUM SP )];
};

subtest "error_messages" => sub {
    my $fmtr = Validator::Procedural::Formatter::Minimal->new(
        fields => {
            abc => 'ABC',
            def => 'DEF',
            ghi => 'GHI',
        },
        errors => {
            FOO => '[_1] foo',
            BAR => 'bar [_1]',
            BAZ => 'baz',
        },
    );

    my $prot = Validator::Procedural::Prototype->new(
        procedures => {
            FOO => sub { $_[0]->add_error('FOO') },
            BAR => sub { $_[0]->add_error('BAR') },
            BAZ => sub { $_[0]->add_error('BAZ') },
        },
        formatter => $fmtr,
    );
    my $vtor = $prot->create_validator();

    $vtor->process('abc', 'FOO');
    $vtor->process('def', 'BAR');
    $vtor->process('ghi', 'BAZ');
    $vtor->process('HOGE', 'FOO');

    is_deeply [ $vtor->error_messages() ], [ 'ABC foo', 'bar DEF', 'baz', 'Hoge foo' ];
};

done_testing;
