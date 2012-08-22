#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::SearchForFiles');
}

my $search_results;
for my $species_regex (('coli', 'escheric', 'E.Coli', 'E coli', 'Escherichia_coli_1', 'Escherichia coli', 'Escherichia_coli '))
{
  species_name_regex($species_regex);
}



done_testing();

sub species_name_regex
{
 my $regex = shift;
  ok(($search_results = Bio::MLST::SearchForFiles->new(
    species_name => $regex,
    base_directory => 't/data'
  )),"initialise searching for files with $regex");
  is_deeply(['t/data/Escherichia_coli_1/alleles/adk.tfa', 't/data/Escherichia_coli_1/alleles/purA.tfa','t/data/Escherichia_coli_1/alleles/recA.tfa'],$search_results->allele_filenames(),"allele filenames for $regex");
  is('t/data/Escherichia_coli_1/profiles/escherichia_coli.txt', $search_results->profiles_filename(),"profiles filename for $regex");
  
}
