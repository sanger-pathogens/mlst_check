#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::Check');
}

my $tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();

ok((my $multiple_fastas = Bio::MLST::Check->new(
  species               => "E.coli",
  base_directory        => 't/data',
  raw_input_fasta_files => ['t/data/contigs.fa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 1
)),'Initialise single valid fasta');
ok(($multiple_fastas->create_result_files),'create all the results files for a single valid fasta');
compare_files('t/data/expected_mlst_results.genomic.csv', $tmpdirectory.'/mlst_results.genomic.csv');
compare_files('t/data/expected_mlst_results.allele.csv', $tmpdirectory.'/mlst_results.allele.csv');
compare_files('t/data/expected_concatenated_alleles.fa', $tmpdirectory.'/concatenated_alleles.fa');

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($multiple_fastas = Bio::MLST::Check->new(
  species               => "E.coli",
  base_directory        => 't/data',
  raw_input_fasta_files => ['t/data/contigs.fa','t/data/contigs_pipe_character_in_seq_name.fa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 1
)),'Initialise 2 files, one with pipe char and no hits');
ok(($multiple_fastas->create_result_files),'create all the results files for two fastas');
compare_files('t/data/expected_two_mlst_results.genomic.csv', $tmpdirectory.'/mlst_results.genomic.csv');
compare_files('t/data/expected_two_mlst_results.allele.csv', $tmpdirectory.'/mlst_results.allele.csv');
compare_files('t/data/expected_two_concatenated_alleles.fa', $tmpdirectory.'/concatenated_alleles.fa');


$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($multiple_fastas = Bio::MLST::Check->new(
  species               => "E.coli",
  base_directory        => 't/data',
  raw_input_fasta_files => ['t/data/contigs.fa','t/data/contigs_pipe_character_in_seq_name.fa','t/data/contigs_one_unknown.tfa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 3
)),'Initialise 3 files where 1 has near matches');
ok(($multiple_fastas->create_result_files),'create all the results files for three fastas');
compare_files('t/data/expected_three_mlst_results.genomic.csv', $tmpdirectory.'/mlst_results.genomic.csv');
compare_files('t/data/expected_three_mlst_results.allele.csv', $tmpdirectory.'/mlst_results.allele.csv');
compare_files('t/data/expected_three_concatenated_alleles.fa', $tmpdirectory.'/concatenated_alleles.fa');
compare_files('t/data/expected_three_contigs_one_unknown.unknown_allele.adk-2.fa', $tmpdirectory.'/contigs_one_unknown.unknown_allele.adk-2.fa');
compare_files('t/data/expected_three_contigs_one_unknown.unknown_allele.recA-1.fa', $tmpdirectory.'/contigs_one_unknown.unknown_allele.recA-1.fa');


done_testing();

sub compare_files
{
  my($expected_file, $actual_file) = @_;
  ok((-e $actual_file),' results file exist');
  local $/ = undef;
  open(EXPECTED, $expected_file);
  open(ACTUAL, $actual_file);
  my $expected_line = <EXPECTED>;
  my $actual_line = <ACTUAL>;
  
  # parallel processes mean the order isnt guaranteed.
  my $sorted_expected = sort(split(/\n/,$expected_line));
  my $sorted_actual  = sort(split(/\n/,$actual_line));
  is_deeply($sorted_expected,$sorted_actual, 'Content matches expected');
}
