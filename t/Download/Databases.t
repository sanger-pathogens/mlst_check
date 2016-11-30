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

note('Download all of the MLST databases from a given XML file on pubMLST.');

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

# Create fake database contents to check if they are overwritten by update
make_path($destination_directory.'/Bordetella_spp/profiles/');
touch($destination_directory.'/Bordetella_spp/profiles/file_to_be_deleted.txt');
make_path($destination_directory.'/Fake_species/profiles/');
touch($destination_directory.'/Fake_species/profiles/file_to_be_kept.txt');

ok((my $database_settings = Bio::MLST::DatabaseSettings->new(filename => 't/data/overall_databases.xml')->settings),"Extract a list of all MLST databases from the pubMLST XML file.");

ok((my $databases = Bio::MLST::Download::Databases->new(
  databases_attributes => $database_settings,
  base_directory  => $destination_directory
)), 'Prepare to download the databases');
ok($databases->update(),'Download all databases to disk.');


ok((-e $destination_directory.'/Bordetella_spp/alleles/abc.fas'), 'Check that the Bordetella allele was downloaded to the correct directory.');
ok((-e $destination_directory.'/Bordetella_spp/alleles/bbb.fas'), 'Check that the Bordetella allele was downloaded to the correct directory.');
ok((-e $destination_directory.'/Bordetella_spp/alleles/ccc.fas'), 'Check that the Bordetella allele was downloaded to the correct directory.');
ok((-e $destination_directory.'/Bordetella_spp/profiles/bordetella.txt'), 'Check that the Bordetella profile was downloaded to the correct directory.');

ok((-e $destination_directory.'/Homo_sapiens_1/alleles/ddd.fas'), 'Check that the other test allele was downloaded to the correct directory.');
ok((-e $destination_directory.'/Homo_sapiens_1/alleles/eee.fas'), 'Check that the other test allele was downloaded to the correct directory.');
ok((-e $destination_directory.'/Homo_sapiens_1/profiles/homo_sapiens.txt'), 'Check that the other test profile was downloaded to the correct directory.');

# Check if the fake database contents are overwritten
ok((! -e $destination_directory.'/Bordetella_spp/profiles/file_to_be_deleted.txt'), "Make sure the species is successfully overwritten after the update.");
ok((-e $destination_directory.'/Fake_species/profiles/file_to_be_kept.txt'), "Make sure other files were not overwritten and replaced by the update if they were not part of the XML file.");


my $destination_directory_obj2 = File::Temp->newdir(CLEANUP =>1);
my $destination_directory2 = $destination_directory_obj2->dirname();

ok((my $database_settings2 = Bio::MLST::DatabaseSettings->new(filename => 't/data/Pediococcus_pentosaceus_filtering.xml')->settings),"Get overall list of databases to be filtered.");

ok((my $databases2 = Bio::MLST::Download::Databases->new(
  databases_attributes => $database_settings2,
  base_directory  => $destination_directory2
)), 'Prepare to download the databases');
ok($databases2->update(),'Make sure that specific databases are not downloaded.');

ok((! (-e $destination_directory2.'/Pediococcus_pentosaceus/alleles/gyrB.tfa')),'Nothing should be downloaded because we have excluded it from the update.' );

done_testing();

