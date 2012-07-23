#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './modules') }
BEGIN {
    use Test::Most;
    use_ok('MLST::Download::ucc');
}

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

ok(my $database = MLST::Download::ucc->new(
  database_attributes => { 
      allele_files => ['t/data/abc.fas','t/data/efg.fas'], 
      strain_files => ['t/data/hij.fas']
    },
  destination_directory => $destination_directory
  ), 'initialise ucc datdabase for download'
);

ok($database->update(), 'update all files');

ok((-e $destination_directory.'/abc.fas'),'downloaded allele file 1');
ok((-e $destination_directory.'/efg.fas'),'downloaded allele file 2');
ok((-e $destination_directory.'/hij.fas'),'downloaded strain file 1');

# check that urls are parsed correctly
is( $database->_get_filename_from_url('http://mlst.abc.com/mlst/Ecoli_123/DB/publicSTs.txt'), 'publicSTs.txt','get filename from url');

done_testing();
