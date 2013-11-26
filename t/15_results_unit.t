use strict;
use Test::More;
use Validator::Procedural;

subtest "value" => sub {
    my $results = Validator::Procedural->new()->results;

    is scalar $results->value('f'), undef;

    $results->value('f', 1);
    is scalar $results->value('f'), 1;

    $results->value('f', 'abc');
    is scalar $results->value('f'), 'abc';

    $results->value('f', qw( a b c ));
    is scalar $results->value('f'), 'a';
    is_deeply [ $results->value('f') ], [qw( a b c )];

    $results->value('f', undef);
    is scalar $results->value('f'), undef;
};

subtest "values" => sub {
    my $results = Validator::Procedural->new()->results;

    $results->value('foo', 'abc');
    $results->value('bar', 'hoge', 'fuga');

    is $results->values->get('foo'), 'abc';
    is $results->values->get('bar'), 'fuga';
    is_deeply [ $results->values->get_all('bar') ], [qw( hoge fuga )];

    is_deeply +{ $results->values }, +{ foo => [qw( abc )], bar => [qw( hoge fuga )] };
    # order keeps
    is_deeply  [ $results->values ],  [ foo => [qw( abc )], bar => [qw( hoge fuga )] ];
};

subtest "success, has_error" => sub {
    my $vldr = Validator::Procedural->new();
    my $results = $vldr->results;

    ok $results->success;
    ok ! $results->has_error;

    $results->value('foo', 'abc');

    ok $results->success;
    ok ! $results->has_error;

    $results->add_error('foo', 'BAD');

    ok ! $results->success;
    ok $results->has_error;

    $vldr->remove_field('foo');

    ok $results->success;
    ok ! $results->has_error;
};

subtest "valid_fields, invalid_fields, valid, invalid" => sub {
    my $vldr = Validator::Procedural->new();
    my $results = $vldr->results;

    $results->value('foo', 'abc');
    $results->value('bar', 'def');
    $results->value('baz', 'ghi');

    is_deeply [$results->valid_fields], [qw( foo bar baz )];
    is_deeply [$results->invalid_fields], [qw( )];
    ok $results->valid('foo');
    ok ! $results->invalid('foo');
    ok $results->valid('bar');
    ok ! $results->invalid('bar');
    ok $results->valid('baz');
    ok ! $results->invalid('baz');

    $results->add_error('bar', 'BAD');
    is_deeply [$results->valid_fields], [qw( foo baz )];
    is_deeply [$results->invalid_fields], [qw( bar )];
    ok $results->valid('foo');
    ok ! $results->invalid('foo');
    ok ! $results->valid('bar');
    ok $results->invalid('bar');
    ok $results->valid('baz');
    ok ! $results->invalid('baz');

    $results->clear_errors('bar');
    $results->add_error('baz', 'BAD');
    is_deeply [$results->valid_fields], [qw( foo bar )];
    is_deeply [$results->invalid_fields], [qw( baz )];
    ok $results->valid('foo');
    ok ! $results->invalid('foo');
    ok $results->valid('bar');
    ok ! $results->invalid('bar');
    ok ! $results->valid('baz');
    ok $results->invalid('baz');

    $vldr->remove_field('bar', 'baz');

    is_deeply [$results->valid_fields], [qw( foo )];
    is_deeply [$results->invalid_fields], [qw( )];
};

# TODO test for filtering mech of #invalid_fields().

subtest "errors, error" => sub {
    my $results = Validator::Procedural->new()->results;
    $results->add_error('foo', 'WORLD');
    $results->add_error('bar', 'HOGE', 'FUGA');

    is_deeply scalar $results->errors, +{ foo => ['WORLD'], bar => ['HOGE', 'FUGA'] };
    is_deeply [ $results->errors ], [ foo => ['WORLD'], bar => ['HOGE', 'FUGA'] ];

    is_deeply [ $results->error('foo') ], ['WORLD'];
    is_deeply [ $results->error('bar') ], ['HOGE', 'FUGA'];
    is_deeply [ $results->error('baz') ], [];
};

subtest "add_error, set_errors, clear_errors" => sub {
    my $results = Validator::Procedural->new()->results;

    $results->add_error('foo', 'HOGE');
    is_deeply [ $results->error('foo') ], ['HOGE'];

    $results->add_error('foo', 'FUGA', 'PYA');
    is_deeply [ $results->error('foo') ], ['HOGE', 'FUGA', 'PYA'];

    $results->set_errors('foo', 'FOO', 'BAR');
    is_deeply [ $results->error('foo') ], ['FOO', 'BAR'];

    $results->clear_errors('foo');
    is_deeply [ $results->error('foo') ], [];

    $results->set_errors('foo', 'FOO', 'BAR');
    $results->set_errors('bar', 'BAZ');
    is_deeply scalar $results->errors, +{ foo => ['FOO', 'BAR'], bar => ['BAZ'] };
    $results->clear_errors();
    is_deeply scalar $results->errors, +{ };
};

done_testing;
