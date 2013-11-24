use strict;
use Test::More;
use Validator::Procedural;

subtest "value" => sub {
    my $vldr = Validator::Procedural->new();

    is scalar $vldr->value('f'), undef;

    $vldr->value('f', 1);
    is scalar $vldr->value('f'), 1;

    $vldr->value('f', 'abc');
    is scalar $vldr->value('f'), 'abc';

    $vldr->value('f', qw( a b c ));
    is scalar $vldr->value('f'), 'a';
    is_deeply [ $vldr->value('f') ], [qw( a b c )];

    $vldr->value('f', undef);
    is scalar $vldr->value('f'), undef;
};

subtest "values" => sub {
    my $vldr = Validator::Procedural->new();

    $vldr->value('foo', 'abc');
    $vldr->value('bar', 'hoge', 'fuga');

    is $vldr->values->get('foo'), 'abc';
    is $vldr->values->get('bar'), 'fuga';
    is_deeply [ $vldr->values->get_all('bar') ], [qw( hoge fuga )];

    is_deeply +{ $vldr->values }, +{ foo => [qw( abc )], bar => [qw( hoge fuga )] };
    # order keeps
    is_deeply  [ $vldr->values ],  [ foo => [qw( abc )], bar => [qw( hoge fuga )] ];
};

subtest "remove_field" => sub {
    my $vldr = Validator::Procedural->new();

    $vldr->value('foo', 'abc');
    $vldr->value('bar', 'def');
    $vldr->value('baz', 'def');
    is_deeply [ $vldr->valid_fields ], [qw( foo bar baz )];

    $vldr->remove_field('bar', 'baz', 'hoge');
    is_deeply [ $vldr->valid_fields ], [qw( foo )];
    is scalar $vldr->value('foo'), 'abc';
    is scalar $vldr->value('bar'), undef;
    is scalar $vldr->value('baz'), undef;
};

subtest "success, has_error" => sub {
    my $vldr = Validator::Procedural->new();

    ok $vldr->success;
    ok ! $vldr->has_error;

    $vldr->value('foo', 'abc');

    ok $vldr->success;
    ok ! $vldr->has_error;

    $vldr->add_error('foo', 'BAD');

    ok ! $vldr->success;
    ok $vldr->has_error;

    $vldr->remove_field('foo');

    ok $vldr->success;
    ok ! $vldr->has_error;
};

subtest "valid_fields, invalid_fields, valid, invalid" => sub {
    my $vldr = Validator::Procedural->new();
    $vldr->value('foo', 'abc');
    $vldr->value('bar', 'def');
    $vldr->value('baz', 'ghi');

    is_deeply [$vldr->valid_fields], [qw( foo bar baz )];
    is_deeply [$vldr->invalid_fields], [qw( )];
    ok $vldr->valid('foo');
    ok ! $vldr->invalid('foo');
    ok $vldr->valid('bar');
    ok ! $vldr->invalid('bar');
    ok $vldr->valid('baz');
    ok ! $vldr->invalid('baz');

    $vldr->add_error('bar', 'BAD');
    is_deeply [$vldr->valid_fields], [qw( foo baz )];
    is_deeply [$vldr->invalid_fields], [qw( bar )];
    ok $vldr->valid('foo');
    ok ! $vldr->invalid('foo');
    ok ! $vldr->valid('bar');
    ok $vldr->invalid('bar');
    ok $vldr->valid('baz');
    ok ! $vldr->invalid('baz');

    $vldr->clear_errors('bar');
    $vldr->add_error('baz', 'BAD');
    is_deeply [$vldr->valid_fields], [qw( foo bar )];
    is_deeply [$vldr->invalid_fields], [qw( baz )];
    ok $vldr->valid('foo');
    ok ! $vldr->invalid('foo');
    ok $vldr->valid('bar');
    ok ! $vldr->invalid('bar');
    ok ! $vldr->valid('baz');
    ok $vldr->invalid('baz');

    $vldr->remove_field('bar', 'baz');
    is_deeply [$vldr->valid_fields], [qw( foo )];
    is_deeply [$vldr->invalid_fields], [qw( )];
};

subtest "errors, error" => sub {
    my $vldr = Validator::Procedural->new();
    $vldr->add_error('foo', 'WORLD');
    $vldr->add_error('bar', 'HOGE', 'FUGA');

    is_deeply scalar $vldr->errors, +{ foo => ['WORLD'], bar => ['HOGE', 'FUGA'] };
    is_deeply [ $vldr->errors ], [ foo => ['WORLD'], bar => ['HOGE', 'FUGA'] ];

    is_deeply [ $vldr->error('foo') ], ['WORLD'];
    is_deeply [ $vldr->error('bar') ], ['HOGE', 'FUGA'];
    is_deeply [ $vldr->error('baz') ], [];
};

subtest "add_error, set_errors, clear_errors" => sub {
    my $vldr = Validator::Procedural->new();

    $vldr->add_error('foo', 'HOGE');
    is_deeply [ $vldr->error('foo') ], ['HOGE'];

    $vldr->add_error('foo', 'FUGA', 'PYA');
    is_deeply [ $vldr->error('foo') ], ['HOGE', 'FUGA', 'PYA'];

    $vldr->set_errors('foo', 'FOO', 'BAR');
    is_deeply [ $vldr->error('foo') ], ['FOO', 'BAR'];

    $vldr->clear_errors('foo');
    is_deeply [ $vldr->error('foo') ], [];

    $vldr->set_errors('foo', 'FOO', 'BAR');
    $vldr->set_errors('bar', 'BAZ');
    is_deeply scalar $vldr->errors, +{ foo => ['FOO', 'BAR'], bar => ['BAZ'] };
    $vldr->clear_errors();
    is_deeply scalar $vldr->errors, +{ };
};

done_testing;
