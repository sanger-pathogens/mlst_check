#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './modules') }
BEGIN {
    use Test::Most;
    use_ok('MLST::CompareAlleles');
}

ok((my $compare_alleles = MLST::CompareAlleles->new(
  sequence_filename => 't/data/contigs.fa',
  allele_filenames => ['t/data/allele1.tfa','t/data/allele2.tfa','t/data/allele3.tfa']
)), 'initialise comparison');

is_deeply(sort(['adk-2','purA-3','recA-1']), $compare_alleles->found_sequence_names, 'correct sequences found');

done_testing();

