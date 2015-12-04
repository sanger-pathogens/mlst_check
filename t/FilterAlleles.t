#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::FilterAlleles', qw(only_keep_alleles));
}

use Bio::MLST::FilterAlleles qw(only_keep_alleles);

my $potential_alleles = ['abc', 'def'];
my $expected_alleles = ['abc', 'def'];

is_deeply(only_keep_alleles($potential_alleles), $expected_alleles, "They were all alleles");

$potential_alleles = ['abc', 'def', 'clonal_complex'];
$expected_alleles = ['abc', 'def'];

is_deeply(only_keep_alleles($potential_alleles), $expected_alleles, "There is a clonal_complex");

done_testing();

