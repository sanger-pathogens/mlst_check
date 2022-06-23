#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::Download::Database');
}

note("Check that the databases on disk can be updated.");

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

ok(my $database = Bio::MLST::Download::Database->new(
  database_attributes => { 
      alleles => ['t/data/abc.fas','t/data/efg.fas'], 
      profiles => 't/data/bordetella.txt'
    },
  base_directory => $destination_directory,
  species => "ABC EFG#1"
  ), 'Given some test allele FASTA files and a profile for a species.'
);

ok($database->update(), 'Update the MLST database for the species');

ok((-e $destination_directory.'/ABC_EFG_1/alleles/abc.fas'),'Check that the first allele file was updated correctly.');
ok((-e $destination_directory.'/ABC_EFG_1/alleles/efg.fas'),'Check that the second allele file was updated correctly.');
ok((-e $destination_directory.'/ABC_EFG_1/profiles/bordetella.txt'),'Check that the profile file was updated correctly.');

# check that urls are parsed correctly
is( $database->_get_filename_from_url('https://rest.pubmlst.org/db/pubmlst_bsubtilis_seqdef/schemes/1/profiles_csv'), 'bsubtilis.txt', 'Make sure the profile filename is correctly parsed from the url.');
is( $database->_get_filename_from_url('https://rest.pubmlst.org/db/pubmlst_blicheniformis_seqdef/loci/sucC/alleles_fasta'), 'sucC.txt', 'Make sure the alleles filename is correctly parsed from the url.');
dies_ok( $database->_get_filename_from_url('https://rest.pubmlst.org/db/pubmlst_blicheniformis_seqdef/loci/sucC/invalid_filename'), 'Die if we encounter unexpected filename in the url.');
dies_ok( $database->_get_filename_from_url('random_str_not_a_url'), 'Die if we cannot parse a filename from the url.');

done_testing();
