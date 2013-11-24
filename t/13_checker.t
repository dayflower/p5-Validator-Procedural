use strict;
use Test::More;
use Validator::Procedural;

subtest "simple checker" => sub {
    my $vldr = Validator::Procedural->new(
        checkers => {
            CHECKER => sub { $_ eq 'a' ? 'A' : 'Z' },
        },
    );

    my $proc = sub { $_[0]->check('CHECKER') };

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, undef);
    is_deeply [ $vldr->error('f') ], [ 'Z' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, "");
    is_deeply [ $vldr->error('f') ], [ 'Z' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, 'a');
    is_deeply [ $vldr->error('f') ], [ 'A' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, qw( a z ));
    is_deeply [ $vldr->error('f') ], [ 'A' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, qw( x a ));
    is_deeply [ $vldr->error('f') ], [ 'Z' ];
};

subtest "checker for multiple" => sub {
    my $vldr = Validator::Procedural->new(
        checkers => {
            CHECKER => sub {
                my $opts = pop @_;
                (grep { $_ eq 'a' } @_) ? 'A' : 'Z';
            },
        },
    );

    my $proc = sub { $_[0]->check('CHECKER') };

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, undef);
    is_deeply [ $vldr->error('f') ], [ 'Z' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, "");
    is_deeply [ $vldr->error('f') ], [ 'Z' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, 'a');
    is_deeply [ $vldr->error('f') ], [ 'A' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, qw( a z ));
    is_deeply [ $vldr->error('f') ], [ 'A' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, qw( x a ));
    is_deeply [ $vldr->error('f') ], [ 'A' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc, qw( x y ));
    is_deeply [ $vldr->error('f') ], [ 'Z' ];
};

subtest "checker with options" => sub {
    my $vldr = Validator::Procedural->new(
        checkers => {
            CHECKER => sub {
                my $opts = pop @_;
                0+$_ > 0+$opts->{c} ? '>' : '<=';
            },
        },
    );

    my $proc1 = sub { $_[0]->check('CHECKER', c => 0) };
    my $proc2 = sub { $_[0]->check('CHECKER', c => 10) };
    my $proc3 = sub { $_[0]->check('CHECKER', c => 20) };

    $vldr->clear_errors('f');
    $vldr->process('f', $proc1, undef);
    is_deeply [ $vldr->error('f') ], [ '<=' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc1, 1);
    is_deeply [ $vldr->error('f') ], [ '>' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc2, 1);
    is_deeply [ $vldr->error('f') ], [ '<=' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc3, 1);
    is_deeply [ $vldr->error('f') ], [ '<=' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc1, 11);
    is_deeply [ $vldr->error('f') ], [ '>' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc2, 11);
    is_deeply [ $vldr->error('f') ], [ '>' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc3, 11);
    is_deeply [ $vldr->error('f') ], [ '<=' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc1, 21);
    is_deeply [ $vldr->error('f') ], [ '>' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc2, 21);
    is_deeply [ $vldr->error('f') ], [ '>' ];

    $vldr->clear_errors('f');
    $vldr->process('f', $proc3, 21);
    is_deeply [ $vldr->error('f') ], [ '>' ];
};

done_testing;
