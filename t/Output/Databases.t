#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::Databases');
}

note('The databases are stored in a directory on disk. Make sure the names can of the species can be lookedup.');

ok((my $mlst_dbs = Bio::MLST::Databases->new(
  base_directory => 't/data/databases',
)),'Set up the class with a valid directory containing MLST databases.');

is_deeply($mlst_dbs->database_names,['Escherichia_coli_1','Helicobacter_pylori','Streptococcus_pyogenes','Streptococcus_pyogenes_emmST'],'List out all the species names of the databases in the database directory.');

done_testing();
