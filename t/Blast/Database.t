#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::Blast::Database');
}

ok((my $blast_database= Bio::MLST::Blast::Database->new(fasta_file => 't/data/contigs.fa')),'Initialise creation of a blast database');

is($blast_database->location, $blast_database->_working_directory->dirname().'/output_contigs', 'location returned correctly');

for my $extension  (('nsq','nsi','nsd','nog','nin','nhr') )
{
  ok((-e  $blast_database->location.".".$extension), 'Intermediate file exists for '.$extension);
}

# Exec not available
dies_ok( sub {Bio::MLST::Blast::Database->new(fasta_file => 't/data/contigs.fa', exec => 'non_existant_executable'); }, 'Validate if the exec is available');

done_testing();
