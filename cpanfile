requires 'perl',             '5.008005';
requires 'Module::Load',     '0';
requires 'Hash::MultiValue', '0';

on 'test' => sub {
    requires 'Test::More',      '0.98';
    requires 'Test::Exception', '0';
};

