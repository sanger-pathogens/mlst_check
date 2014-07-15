#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN {
    use Test::Most;
}

my $tmp_out_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $tmp_out_directory = $tmp_out_directory_obj->dirname();

ok(system("perl bin/get_sequence_type  -s 'Streptococcus Pneumonia' t/data/main_input_contig.fa -o $tmp_out_directory") == 0, 'main binary testing');
compare_files('t/data/main_expected_mlst_results.genomic.csv', $tmp_out_directory.'/mlst_results.genomic.csv');
compare_files('t/data/main_expected_mlst_results.allele.csv', $tmp_out_directory.'/mlst_results.allele.csv');

# With -md5 option
ok(system("perl bin/get_sequence_type  -s 'Streptococcus Pneumonia' t/data/main_input2_contig.fa -md5 -o $tmp_out_directory") == 0, 'main binary testing');
compare_files('t/data/main_expected_mlst_results_md5.genomic.csv', $tmp_out_directory.'/mlst_results.genomic.csv');
compare_files('t/data/main_expected_mlst_results_md5.allele.csv', $tmp_out_directory.'/mlst_results.allele.csv');
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