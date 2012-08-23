#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::Download::Database');
}

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

ok(my $database = Bio::MLST::Download::Database->new(
  database_attributes => { 
      alleles => ['t/data/abc.fas','t/data/efg.fas'], 
      profiles => 't/data/bordetella.txt'
    },
  base_directory => $destination_directory,
  species => "ABC EFG#1"
  ), 'initialise ucc datdabase for download'
);

ok($database->update(), 'update all files');

ok((-e $destination_directory.'/ABC_EFG_1/alleles/abc.fas'),'downloaded allele file 1');
ok((-e $destination_directory.'/ABC_EFG_1/alleles/efg.fas'),'downloaded allele file 2');
ok((-e $destination_directory.'/ABC_EFG_1/profiles/bordetella.txt'),'downloaded strain file 1');

# check that urls are parsed correctly
is( $database->_get_filename_from_url('http://mlst.abc.com/mlst/Ecoli_123/DB/publicSTs.txt'), 'publicSTs.txt','get filename from url');

done_testing();
