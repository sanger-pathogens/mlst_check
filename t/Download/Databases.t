#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::DatabaseSettings');
    use_ok('Bio::MLST::Download::Databases');
}

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

ok((my $database_settings = Bio::MLST::DatabaseSettings->new(filename => 't/data/overall_databases.xml')->settings),"get overall list of databases");

ok((my $databases = Bio::MLST::Download::Databases->new(
  databases_attributes => $database_settings,
  base_directory  => $destination_directory
)), 'download databases initialisation');
ok($databases->update(),'download all databases');


ok((-e $destination_directory.'/Bordetella_spp/alleles/abc.fas'));
ok((-e $destination_directory.'/Bordetella_spp/alleles/bbb.fas'));
ok((-e $destination_directory.'/Bordetella_spp/alleles/ccc.fas'));
ok((-e $destination_directory.'/Bordetella_spp/profiles/bordetella.txt'));

ok((-e $destination_directory.'/Homo_sapiens_1/alleles/ddd.fas'));
ok((-e $destination_directory.'/Homo_sapiens_1/alleles/eee.fas'));
ok((-e $destination_directory.'/Homo_sapiens_1/profiles/homo_sapiens.txt'));

done_testing();

