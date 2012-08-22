#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::DatabaseSettings');
}

ok((my $database_settings = Bio::MLST::DatabaseSettings->new(filename     => 't/data/overall_databases.xml')), 'initialise database settings');
ok((my $settings  = $database_settings->settings), 'get settings datastructure');

is($settings->{"Bordetella spp."}->{profiles}, "t/data/bordetella.txt", 'get profile url');
is($settings->{"Bordetella spp."}->{alleles}->[0],"t/data/abc.fas", 'get an allele file'); 
is($settings->{"Bordetella spp."}->{alleles}->[1],"t/data/bbb.fas", 'get another allele file');


is($settings->{"Homo sapiens#1"}->{profiles}, "t/data/homo_sapiens.txt", 'get a different profile url');
is($settings->{"Homo sapiens#1"}->{alleles}->[0],"t/data/ddd.fas", 'get an allele file'); 
is($settings->{"Homo sapiens#1"}->{alleles}->[1],"t/data/eee.fas", 'get another allele file');

done_testing();
