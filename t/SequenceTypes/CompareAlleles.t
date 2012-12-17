#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::CompareAlleles');
}

ok((my $compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk.tfa','t/data/purA.tfa','t/data/recA.tfa']
)), 'initialise comparison');
is_deeply( $compare_alleles->found_sequence_names,sort(['adk-2','purA-3','recA-1']), 'correct sequences found');
is_deeply( $compare_alleles->non_matching_sequences, {}, 'no non matching sequences returned');
is($compare_alleles->new_st, 0, 'existing ST found');
is($compare_alleles->contamination, 0, 'no contamination found');

ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_top_hit_low_hit.tfa']
)), 'initialise comparison where there are multiple close matches');
is_deeply( $compare_alleles->found_sequence_names,sort(['adk-2']), 'correct sequences identified from closely related');
is_deeply( $compare_alleles->non_matching_sequences, {}, 'no non matching sequences returned');
is($compare_alleles->new_st, 0, 'existing ST found');
is($compare_alleles->contamination, 0, 'contamination found');

ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_contamination.tfa']
)), 'initialise comparison where there is contamination');
is_deeply( $compare_alleles->found_sequence_names,sort(['adk-3']), 'last top hit returned if more than 1 is 100%');
is($compare_alleles->new_st, 0, 'existing ST found');
is($compare_alleles->contamination, 1, 'contamination found');

ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_less_than_95_percent.tfa']
)), 'initialise comparison where no hits are returned');
is_deeply( $compare_alleles->found_sequence_names, [], 'no matching sequences found');
is_deeply( $compare_alleles->non_matching_sequences, {'adk_less_than_95_percent' => 'NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN'}, 'non matching sequences returned');
is($compare_alleles->new_st, 1, 'new ST found');
is($compare_alleles->contamination, 0, 'no contamination found');

ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs_missing_locus.fa',
  allele_filenames => ['t/data/Helicobacter_pylori/alleles/atpA.tfa',' t/data/Helicobacter_pylori/alleles/efp.tfa','t/data/Helicobacter_pylori/alleles/mutY.tfa']
)), 'initialise comparison where profile has missing locus');
is_deeply( $compare_alleles->found_sequence_names,sort(['atpA-3','efp-9999','mutY-3']), 'correct sequences found');
is_deeply( $compare_alleles->non_matching_sequences, {}, 'no non matching sequences returned');
is($compare_alleles->new_st, 0, 'existing ST found');
is($compare_alleles->contamination, 0, 'no contamination found');

done_testing();

