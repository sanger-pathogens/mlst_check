#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::SearchForFiles');
}

note("Given a partial name of a species, lookup the underlying MLST scheme. We use Escherichia coli for this test as it has 2 schemes and is commonly referred to by its short name.");

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
    base_directory => 't/data/databases'
  )),"Given the query $regex begin the search for matching MLST schemes.");
  my @results = sort @{$search_results->allele_filenames()};
  my @expected_results = ('t/data/databases/Escherichia_coli_1/alleles/adk.tfa', 't/data/databases/Escherichia_coli_1/alleles/purA.tfa','t/data/databases/Escherichia_coli_1/alleles/recA.tfa');
  is_deeply(\@results, \@expected_results, "All allele files for $regex were correctly found.");
  is('t/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt', $search_results->profiles_filename(),"The profile file for $regex was correctly found.");
  
}
