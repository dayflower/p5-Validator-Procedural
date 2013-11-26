use strict;
use Test::More;
use Validator::Procedural;

subtest "EXISTS" => sub {
    my $prot = Validator::Procedural::Prototype->new();
    my $vtor = $prot->create_validator();
    $vtor->register_rule_class('::General');

    $vtor->process('field1', sub {
        $_[0]->check('EXISTS');
    }, undef);
    is_deeply [ $vtor->results->error('field1') ], [ 'MISSING' ];

    $vtor->process('field2', sub {
        $_[0]->check('EXISTS');
    }, "");
    is_deeply [ $vtor->results->error('field2') ], [ 'MISSING' ];

    $vtor->process('field3', sub {
        $_[0]->check('EXISTS');
    }, " a ");
    ok $vtor->results->valid('field3');
};

done_testing;
