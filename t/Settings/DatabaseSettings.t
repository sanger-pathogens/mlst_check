#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './modules') }
BEGIN {
    use Test::Most;
    use_ok('MLST::DatabaseSettings');
}

ok((my $database_settings = MLST::DatabaseSettings->new(filename     => 'config/test/database.json')), 'initialise database settings');
ok((my $settings  = $database_settings->settings), 'get settings datastructure');

is($settings->{ucc}->[0]->{genus}, "Escherichia", 'get first genus');
is($settings->{ucc}->[1]->{species}, "sapiens", 'get second species');
is($settings->{ucc}->[1]->{allele_files}->[1],"t/data/ggg.fas", 'get a file'); 

is($settings->{pasteur}->[0]->{genus}, "BBB", 'get first genus');
is($settings->{pasteur}->[1]->{species}, "sapiens", 'get second species');
is($settings->{pasteur}->[1]->{allele_files}->[1],"t/data/ggg.fas", 'get a file');

done_testing();
