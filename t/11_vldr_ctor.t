use strict;
use Test::More;
use Test::Exception;
use Validator::Procedural;

package _Formatter1;
sub format { return 'formatter1' }

package _Formatter2;
sub format { return 'formatter2' }

package main;

subtest "ctor" => sub {
    my $vldr = Validator::Procedural->new(
        filters => {
            FILTER1 => sub { 'FILTER1' },
            FILTER2 => sub { 'FILTER2' },
        },
        rules => {
            RULE1 => sub { return 'RULE1' },
            RULE2 => sub { return 'RULE2' },
        },
        procedures => {
            procedure1 => sub { $_[0]->add_error('procedure1') },
            procedure2 => sub { $_[0]->add_error('procedure2') },
        },
        formatter => '_Formatter1',
    );

    $vldr->process('f1', sub { $_[0]->apply_filter('FILTER1') }, "");
    is $vldr->results->value('f1'), 'FILTER1';

    $vldr->process('f2', sub { $_[0]->apply_filter('FILTER2') }, "");
    is $vldr->results->value('f2'), 'FILTER2';

    $vldr->process('f3', sub { $_[0]->check('RULE1') }, "");
    is_deeply [ $vldr->results->error('f3') ], [ 'RULE1' ];

    $vldr->process('f4', sub { $_[0]->check('RULE2') }, "");
    is_deeply [ $vldr->results->error('f4') ], [ 'RULE2' ];

    $vldr->process('f5', 'procedure1', "");
    is_deeply [ $vldr->results->error('f5') ], [ 'procedure1' ];

    $vldr->process('f6', 'procedure2', "");
    is_deeply [ $vldr->results->error('f6') ], [ 'procedure2' ];

    is $vldr->results->formatter->format('f0', 'ERROR1'), 'formatter1';

    # absent filter / rule / procedure

    throws_ok { $vldr->process('f7', sub { $_[0]->apply_filter('FILTERx') }, "") } qr{Undefined \s+ filter}ixms, "raise undefined filter";

    throws_ok { $vldr->process('f8', sub { $_[0]->check('RULEx') }, "") } qr {Undefined \s+ rule}ixms, "raise undefined rule";

    throws_ok { $vldr->process('f9', 'procedurex', "") } qr{Undefined \s+ procedure}ixms, "raise undefined procedure";
};

subtest "register_filter" => sub {
    my $vldr = Validator::Procedural->new(
        filters => {
            FILTER1 => sub { 'C1' },
            FILTER2 => sub { 'C2' },
        },
    );

    $vldr->register_filter(
        FILTER2 => sub { 'c2' },
        FILTER3 => sub { 'c3' },
    );

    $vldr->process('f1', sub { $_[0]->apply_filter('FILTER1') }, "");
    is $vldr->results->value('f1'), 'C1';

    $vldr->process('f2', sub { $_[0]->apply_filter('FILTER2') }, "");
    is $vldr->results->value('f2'), 'c2';

    $vldr->process('f3', sub { $_[0]->apply_filter('FILTER3') }, "");
    is $vldr->results->value('f3'), 'c3';
};

subtest "register_rule" => sub {
    my $vldr = Validator::Procedural->new(
        rules => {
            RULE1 => sub { 'C1' },
            RULE2 => sub { 'C2' },
        },
    );

    $vldr->register_rule(
        RULE2 => sub { 'c2-1', 'c2-2' },
        RULE3 => sub { 'c3' },
    );

    $vldr->process('f1', sub { $_[0]->check('RULE1') }, "");
    is_deeply [ $vldr->results->error('f1') ], [ 'C1' ];

    $vldr->process('f2', sub { $_[0]->check('RULE2') }, "");
    is_deeply [ $vldr->results->error('f2') ], [ 'c2-1', 'c2-2' ];

    $vldr->process('f3', sub { $_[0]->check('RULE3') }, "");
    is_deeply [ $vldr->results->error('f3') ], [ 'c3' ];
};

subtest "register_procedure" => sub {
    my $vldr = Validator::Procedural->new(
        procedures => {
            procedure1 => sub { $_[0]->add_error('P1') },
            procedure2 => sub { $_[0]->add_error('P2') },
        },
    );

    $vldr->register_procedure(
        procedure2 => sub { $_[0]->add_error('p2') },
        procedure3 => sub { $_[0]->add_error('p3') },
    );

    $vldr->process('f1', 'procedure1', "");
    is_deeply [ $vldr->results->error('f1') ], [ 'P1' ];

    $vldr->process('f2', 'procedure2', "");
    is_deeply [ $vldr->results->error('f2') ], [ 'p2' ];

    $vldr->process('f3', 'procedure3', "");
    is_deeply [ $vldr->results->error('f3') ], [ 'p3' ];
};

subtest "formatter" => sub {
    my $vldr = Validator::Procedural->new(
        formatter => '_Formatter1',
    );

    $vldr->formatter('_Formatter2');

    is $vldr->formatter->format('f0', 'ERROR1'), 'formatter2';
};

done_testing;
