use strict;
use Test::More;

use_ok $_ for qw(
    Validator::Procedural
    Validator::Procedural::Prototype
    Validator::Procedural::Results
    Validator::Procedural::Field
    Validator::Procedural::Formatter::Minimal
);

done_testing;

