#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::CompareAlleles');
}

note('Taking an input assembly,compare it to a set of alleles, and return the matching alleles, and flag characteristics.');

note('A contamination free assembly containing alleles contained in the MLST scheme.');
ok((my $compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk.tfa','t/data/purA.tfa','t/data/recA.tfa'],
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
)), 'Compare assembly containing all genes from an MLST scheme');
is_deeply( $compare_alleles->found_sequence_names,sort(['adk-2','purA-3','recA-1']), 'All of the MLST alleles were found in the assembly.');
is_deeply( $compare_alleles->non_matching_sequences, {}, 'No non-matching alleles were found as expected.');
is($compare_alleles->new_st, 0, 'As all the alleles were found, it is not a New ST.');
is($compare_alleles->contamination, 0, 'No contamination found since there is only a single allele for each gene.');

note('A contamination free assembly containing 1 alelle with multiple close matches to an allele in the MLST scheme.');
ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_top_hit_low_hit.tfa'],
    profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
)), 'Compare assembly containing 1 previously unseen allele where there are multiple close matches to a previously seen allele.');
is_deeply( $compare_alleles->found_sequence_names,sort(['adk-2']), 'Identified the nearest match to an allele in the database, based match with most bases in common and highest percentage identity.');
is_deeply( $compare_alleles->non_matching_sequences, {}, 'No non-matching alleles were found as expected');
is($compare_alleles->new_st, 0, 'This isnt a New ST combination, because it contains a Novel allele.');
is($compare_alleles->contamination, 0, 'No contamination found since there is only a single allele for each gene.');

note('A contaminated assembly where there is an exact match more than once to the same allele');
ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_contamination.tfa'],
    profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
)), 'Pass in a contaminated assembly');
is_deeply( $compare_alleles->found_sequence_names,sort(['adk-3']), 'Return the last blast hit returned if more than 1 alelle is a 100% and exact matching length.');
is($compare_alleles->new_st, 0, 'This isnt a new ST as exact matches have been found.');
is($compare_alleles->contamination, 1, 'There is contamination since more than 1 allele is found with 100% accuracy.');
is_deeply($compare_alleles->contamination_sequence_names, [], 'Contamination sequence names not listed because its the same single allele twice.');

note('A contaminated assembly where there are matches to more an 1 allele for a single gene.');
ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_imperfect_contamination.tfa'],
    profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
)), 'Pass in an assembly where there is contamination for a single gene to different alleles.');
is_deeply( $compare_alleles->found_sequence_names,sort(['adk-3']), 'The longest good match is returned, or the last hit if they are identical.');
is_deeply( $compare_alleles->found_non_matching_sequence_names,sort([]), 'No non matching sequences found since they matched preexisting alleles.');
is($compare_alleles->new_st, 0, 'This isnt a new ST as exact matches have been found.');
is($compare_alleles->contamination, 1, 'Flag that contamination has been found.');
is($compare_alleles->contamination_alleles, 'adk-2~,adk-3', 'List the names of the alleles containing contamination, where one is a perfect match and the other is imperfect.');

note('A contaminated assembly where there are imperfect matches to more an 1 allele for a single gene.');
ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_two_imperfect_contamination.tfa'],
    profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
)), 'Pass in an assembly where there is contamination for a single gene to different previously unseen alleles.');
is_deeply( $compare_alleles->found_sequence_names, [], 'No perfect matches to a known allele.');
is_deeply( $compare_alleles->found_non_matching_sequence_names, ['adk-3~'], 'The nearest non matching allele is found, with the most bases in common and the highest identity.');
is($compare_alleles->new_st, 1, 'This is a new ST as novel sequences have been found.');
is($compare_alleles->contamination, 1, 'Flag that contamination has been found.');
is($compare_alleles->contamination_alleles, 'adk-2~,adk-3~', 'List the names of the imperfect alleles containing the contamination.');

note('An assembly contains a single gene which is an imperfect match to whats in the database.');
ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_imperfect.tfa'],
    profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
)), 'Pass in an assembly containing a single gene which is an imperfect match.');
is_deeply( $compare_alleles->found_sequence_names, [], 'No perfect hit were found as expected.');
is_deeply( $compare_alleles->found_non_matching_sequence_names, ['adk-3~'], 'The nearest allele is to the imperfect one is returned.');
is($compare_alleles->new_st, 1, 'This is a new ST as novel sequences have been found.');
is($compare_alleles->contamination, 0, 'The contamination flag should not be set since theres no contamination.');
is($compare_alleles->contamination_alleles, undef, 'No contamination alleles should be listed since there no contamination.');

note('An assembly where there are no hits to any of the alles in the database.');
ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/adk_less_than_95_percent.tfa'],
    profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
)), 'Pass in an assembly where there are less than 95% hits to an existing database.');
is_deeply( $compare_alleles->found_sequence_names, [], 'No matching sequences found as expected.');
is_deeply( $compare_alleles->non_matching_sequences, {'adk_less_than_95_percent' => 'NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN'}, 'If there are no matching sequences for an allele, then pad out the returned allele sequence with Ns.');
is($compare_alleles->new_st, 1, 'As there no exact matches this could be a new ST.');
is($compare_alleles->contamination, 0, 'No contamination or duplication of alleles is found.');

note('An assembly where there is a mismatch between the allele names and the profile.');
ok(($compare_alleles = Bio::MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs_missing_locus.fa',
  allele_filenames => ['t/data/databases/Helicobacter_pylori/alleles/atpA.tfa',' t/data/databases/Helicobacter_pylori/alleles/efp.tfa','t/data/databases/Helicobacter_pylori/alleles/mutY.tfa'],
    profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
)), 'An assembly where there is a mismatch between the allele names and the profile.');
is_deeply( $compare_alleles->found_sequence_names,sort(['atpA-3','efp-9999','mutY-3']), 'The correct alleles are found in the assembly.');
is_deeply( $compare_alleles->non_matching_sequences, {}, 'No non matching sequences returned as expected.');
is($compare_alleles->new_st, 0, 'As there are only exact matches, this isnt a new ST.');
is($compare_alleles->contamination, 0, 'No contamination found.');

done_testing();

