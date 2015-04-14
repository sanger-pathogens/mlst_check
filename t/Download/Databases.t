#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

use File::Touch qw(touch);
use File::Path qw(make_path);

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::DatabaseSettings');
    use_ok('Bio::MLST::Download::Databases');
}

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

# Create fake database contents to check if they are overwritten by update
make_path($destination_directory.'/Bordetella_spp/profiles/');
touch($destination_directory.'/Bordetella_spp/profiles/file_to_be_deleted.txt');
make_path($destination_directory.'/Fake_species/profiles/');
touch($destination_directory.'/Fake_species/profiles/file_to_be_kept.txt');

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

# Check if the fake database contents are overwritten
ok((! -e $destination_directory.'/Bordetella_spp/profiles/file_to_be_deleted.txt'), "species is successfully overwritten");
ok((-e $destination_directory.'/Fake_species/profiles/file_to_be_kept.txt'), "species is not overwritten");


my $destination_directory_obj2 = File::Temp->newdir(CLEANUP =>1);
my $destination_directory2 = $destination_directory_obj2->dirname();

ok((my $database_settings2 = Bio::MLST::DatabaseSettings->new(filename => 't/data/Pediococcus_pentosaceus_filtering.xml')->settings),"get overall list of databases to be filtered");

ok((my $databases2 = Bio::MLST::Download::Databases->new(
  databases_attributes => $database_settings2,
  base_directory  => $destination_directory2
)), 'initalise setting up databases');
ok($databases2->update(),'download databases (nothing should happen)');

ok((! (-e $destination_directory2.'/Pediococcus_pentosaceus/alleles/gyrB.tfa')),'nothing should be downloaded' );

done_testing();

