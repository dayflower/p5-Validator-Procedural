use strict;
use Test::More;
use Validator::Procedural;

subtest "TRIM" => sub {
    my $prot = Validator::Procedural::Prototype->new();
    my $vtor = $prot->create_validator();
    $vtor->register_filter_class('::General');

    $vtor->process('field1', sub {
        $_[0]->apply_filter('TRIM');
    }, undef);
    is scalar $vtor->results->value('field1'), undef;

    $vtor->process('field2', sub {
        $_[0]->apply_filter('TRIM');
    }, "abc");
    is scalar $vtor->results->value('field2'), "abc";

    $vtor->process('field3', sub {
        $_[0]->apply_filter('TRIM');
    }, " def ");
    is scalar $vtor->results->value('field3'), "def";
};

done_testing;
