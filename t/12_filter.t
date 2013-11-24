use strict;
use Test::More;
use Validator::Procedural;

subtest "simple filter" => sub {
    my $vldr = Validator::Procedural->new(
        filters => {
            FILTER => sub { 'F:' . $_ },
        },
    );

    my $proc = sub { $_[0]->apply_filter('FILTER') };

    $vldr->process('f', $proc, undef);
    is scalar $vldr->value('f'), undef;

    $vldr->process('f', $proc, "");
    is scalar $vldr->value('f'), 'F:';

    $vldr->process('f', $proc, "X");
    is scalar $vldr->value('f'), 'F:X';

    $vldr->process('f', $proc, qw( a b c ));
    is scalar $vldr->value('f'), 'F:a';
    is_deeply [ $vldr->value('f') ], [qw( F:a F:b F:c )];
};

subtest "filter with options" => sub {
    my $vldr = Validator::Procedural->new(
        filters => {
            FILTER => sub {
                my ($val, $opts) = @_;
                return join(':', $opts->{prefix}, $val, $opts->{suffix});
            },
        },
    );

    my $proc1 = sub {
        $_[0]->apply_filter('FILTER', prefix => 'abc', suffix => 'xyz');
    };

    $vldr->process('f', $proc1, undef);
    is scalar $vldr->value('f'), undef;

    $vldr->process('f', $proc1, "");
    is scalar $vldr->value('f'), 'abc::xyz';

    $vldr->process('f', $proc1, "X");
    is scalar $vldr->value('f'), 'abc:X:xyz';

    $vldr->process('f', $proc1, qw( a b c ));
    is scalar $vldr->value('f'), 'abc:a:xyz';
    is_deeply [ $vldr->value('f') ], [qw( abc:a:xyz abc:b:xyz abc:c:xyz )];

    my $proc2 = sub {
        $_[0]->apply_filter('FILTER', prefix => 'ABC', suffix => 'XYZ');
    };

    $vldr->process('f', $proc2, undef);
    is scalar $vldr->value('f'), undef;

    $vldr->process('f', $proc2, "");
    is scalar $vldr->value('f'), 'ABC::XYZ';

    $vldr->process('f', $proc2, "X");
    is scalar $vldr->value('f'), 'ABC:X:XYZ';

    $vldr->process('f', $proc2, qw( a b c ));
    is scalar $vldr->value('f'), 'ABC:a:XYZ';
    is_deeply [ $vldr->value('f') ], [qw( ABC:a:XYZ ABC:b:XYZ ABC:c:XYZ )];
};

done_testing;
