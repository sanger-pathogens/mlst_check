#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN {
    use Test::Most;
}

my $tmp_out_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $tmp_out_directory = $tmp_out_directory_obj->dirname();

ok(system("perl bin/get_emm_sequence_type t/data/Streptococcus_pyogenes_emmST_contigs.fa -o $tmp_out_directory") == 0, 'main binary testing');
compare_files('t/data/expected_Streptococcus_pyogenes_emm.genomic.csv', $tmp_out_directory.'/emm_results.genomic.csv');
compare_files('t/data/expected_Streptococcus_pyogenes_emm.allele.csv', $tmp_out_directory.'/emm_results.allele.csv');
done_testing();

sub compare_files
{
  my($expected_file, $actual_file) = @_;
  ok((-e $actual_file),' results file exist');
  ok((-e $expected_file)," $expected_file expected file exist");
  local $/ = undef;
  open(EXPECTED, $expected_file);
  open(ACTUAL, $actual_file);
  my $expected_line = <EXPECTED>;
  my $actual_line = <ACTUAL>;
  
  # parallel processes mean the order isnt guaranteed.
  my @split_expected  = split(/\n/,$expected_line);
  my @split_actual  = split(/\n/,$actual_line);
  my @sorted_expected = sort(@split_expected);
  my @sorted_actual  = sort(@split_actual);
  
  is_deeply(\@sorted_expected,\@sorted_actual, "Content matches expected $expected_file");
}