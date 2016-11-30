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
is( $database->_get_filename_from_url('http://mlst.abc.com/mlst/Ecoli_123/DB/publicSTs.txt'), 'publicSTs.txt','Make sure the profile name is correctly parsed from the url.');

done_testing();
