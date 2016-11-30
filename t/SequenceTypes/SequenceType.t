#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::SequenceType');
}
note('Taking a profile and a list of matching/partial matching alleles, look up the corresponding ST.');

ok((my $sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2','purA-3','recA-1'],
  non_matching_names => []
)), 'The perfect case where the exact alleles correspond to an existing profile.');
is($sequence_type->sequence_type, 4, 'Return an exact match to an ST.');
is($sequence_type->nearest_sequence_type,undef, 'An exact match is found so we dont expect any nearby STs to be returned.');

ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2','purA-3','recA-200'],
  non_matching_names => [],
  report_lowest_st => 1
)), 'The sequence type that doesnt exist in profile, but the alleles are all known.');
is($sequence_type->sequence_type, undef, 'The ST doesnt exist so for this combination of alleles, so shouldnt be returned.');
is($sequence_type->nearest_sequence_type,1, 'The nearest ST should be returned where it has the most alleles in common and is the lowest number.');

ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2','purA-3'],
  non_matching_names => [],
  report_lowest_st => 1
)), 'Only 2 out of 3 alleles in the profile are found.');
is( $sequence_type->sequence_type, undef, 'As one allele is missing, no ST can be found as there is no exact match.');
is($sequence_type->nearest_sequence_type, 1, 'The nearest ST gets returned where it has the most alleles in common and is the lowest integer number if there is more than 1.');

ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Streptococcus_pyogenes/profiles/spyogenes.txt',
  matching_names => ['gki-2','gtr-2','muri-1','muts-2','recp-2','xpt-2','yqil-2'],
  non_matching_names => []
)), 'The ST profile has an underscore suffix so there isnt an exact match to the allele names in the FASTA files. Allow for this.');
is( $sequence_type->sequence_type, 3, 'There is an exact match to an ST once the underscores have been stripped out.');
is($sequence_type->nearest_sequence_type, undef, 'As an exact match has been found, no nearest match is returned.');

ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2','purA-3'],
  non_matching_names => [],
  report_lowest_st => 0
)), 'One of the alleles is missing, and we only want the nearest match, not the lowest ST number.');
is( $sequence_type->sequence_type, undef, 'Theres no exact match so no ST is returned.');
like($sequence_type->nearest_sequence_type, 'm/[14]/', 'The nearest matching ST is given, rather than the lowest number ST.');

ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => [],
  non_matching_names => ['adk-2~','purA-3~','recA-1~'],
  report_lowest_st => 0
)), 'All of the input alleles are partial matches so try to find the nearest ST.');
is( $sequence_type->sequence_type, undef, 'No perfect alleles so no exact ST can be returned.');
is($sequence_type->nearest_sequence_type, '4', 'The nearest matching ST to the partially matching alleles is returned.');

ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2'],
  non_matching_names => ['purA-3~','recA-1~'],
  report_lowest_st => 0
)), 'There is a mixture of exact matches to the alleles and partial matches to the alleles, so return the nearest ST.');
is( $sequence_type->sequence_type, undef, 'One perfect alleles, and 2 partial alleles mean there is no exact match to an ST.');
is($sequence_type->nearest_sequence_type, '4', 'Find the nearest matching ST and return it.');

ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2'],
  non_matching_names => ['purA-3~'],
  report_lowest_st => 0
)), 'Based on the input alleles, 1 partial, 1 exact, and 1 missing there are multiple possible matching STs.');
is( $sequence_type->sequence_type, undef, 'No perfect match so no exact ST can be returned.');
is($sequence_type->nearest_sequence_type, '1', 'Return the nearest matching ST based on really bad input data.');

note('For a pair of STs, compare the alleles and say if they are similar or not.');
$sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => [],
  non_matching_names => []
);
is($sequence_type->_allele_numbers_similar('1', '1'), 1, 'Both STs are identical and perfect matches so they are similar.');
is($sequence_type->_allele_numbers_similar('1', '2'), 0, 'The STs are perfect matches, but to different STs, so are not similar.');
is($sequence_type->_allele_numbers_similar('1', '1~'), 1, 'One ST is a perfect match and the other an imperfect match to the same ST, so they are similar.');
is($sequence_type->_allele_numbers_similar('1~', '1'), 1, 'The first ST is an imperfect match and the other a perfect match to the same ST, so they are similar.');
is($sequence_type->_allele_numbers_similar('1~', '1~'), 1, 'Both STs are imperfect maches to the same ST, so are similar.');
is($sequence_type->_allele_numbers_similar('1', '2~'), 0, 'One ST is perfect, the other is imperfect, but to different STs, so they are not similar.');

done_testing();
