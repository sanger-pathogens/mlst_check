#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::FilterAlleles', qw(only_keep_alleles));
}

note("The MLST profiles occasionally include extra columns, such as clonal complex, which are not genes. These need to be identified and filtered out.");

my $potential_alleles = ['abc', 'def'];
my $expected_alleles = ['abc', 'def'];

is_deeply(only_keep_alleles($potential_alleles), $expected_alleles, "All the input alleles look like real alleles, so all kept.");

$potential_alleles = ['abc', 'def', 'clonal_complex'];
$expected_alleles = ['abc', 'def'];

is_deeply(only_keep_alleles($potential_alleles), $expected_alleles, "There is a clonal_complex in the potential alleles in the input list. It got filtered out.");

done_testing();
