#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './modules') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::Databases');
}

ok((my $mlst_dbs = Bio::MLST::Databases->new(
  base_directory => 't/data',
)),'initialise available databases');

is_deeply($mlst_dbs->database_names,['Escherichia_coli_1'],'list out database names');

done_testing();
