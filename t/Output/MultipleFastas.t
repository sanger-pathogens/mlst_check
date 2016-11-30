#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;
use Cwd;
use Data::Dumper;
use String::Util 'trim';

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::Check');
}

note("At a high level pass in assemblies and check that the expected output result files are generated.");

my $tmpdirectory_obj = File::Temp->newdir(DIR => getcwd, CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();

ok((my $multiple_fastas = Bio::MLST::Check->new(
  species               => "E.coli",
  base_directory        => 't/data/databases',
  raw_input_fasta_files => ['t/data/contigs.fa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 1
)),'Pass in a single assembly with full length alleles and a known ST');
ok(($multiple_fastas->create_result_files),'Create all the results files for a single valid assembly.');
compare_files($tmpdirectory.'/mlst_results.genomic.csv', 't/data/expected_mlst_results.genomic.csv', 'Spreadsheet with sequences of each matching allele for a valid assembly has been created.');
compare_files($tmpdirectory.'/mlst_results.allele.csv', 't/data/expected_mlst_results.allele.csv','Spreadsheet with each matching allele number and ST for a valid assembly has been created.');
compare_files($tmpdirectory.'/concatenated_alleles.fa', 't/data/expected_concatenated_alleles.fa', 'A multi-FASTA file of concatenated MLST sequences for a valid assembly has been created.');

note('Check we can deal with sequences from GenBank which contain pipe characters in the sequence names of the assemblies.');
$tmpdirectory_obj = File::Temp->newdir(DIR => getcwd, CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($multiple_fastas = Bio::MLST::Check->new(
  species               => "E.coli",
  base_directory        => 't/data/databases',
  raw_input_fasta_files => ['t/data/contigs.fa','t/data/contigs_pipe_character_in_seq_name.fa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 1
)),'Pass in 2 assembly files,one valid normal file, and one with pipe character in the sequence name and no hits');
ok(($multiple_fastas->create_result_files),'Create one set of combined results files for the input assemblies.');
compare_files($tmpdirectory.'/mlst_results.genomic.csv', 't/data/expected_two_mlst_results.genomic.csv', 'Spreadsheet with sequences for each matching allele for the two assemblies.');
compare_files($tmpdirectory.'/mlst_results.allele.csv', 't/data/expected_two_mlst_results.allele.csv', 'Spreadsheet with each matching allele number and ST for the two assemblies.');
compare_files($tmpdirectory.'/concatenated_alleles.fa', 't/data/expected_two_concatenated_alleles.fa','Create a multi-FASTA file of concatenated MLST sequences, where the assembly with no hits is padded out with Ns');

note('Make sure the the allele sequences are concatenated in the correct order, otherwise treebuilding wont make any sense.');
$tmpdirectory_obj = File::Temp->newdir(DIR => getcwd, CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($multiple_fastas = Bio::MLST::Check->new(
  species               => "E.coli",
  base_directory        => 't/data/databases',
  raw_input_fasta_files => ['t/data/contigs.fa','t/data/contigs_check_concat_allele_order.fa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 1
)),'Pass in 2 assemblies, one valid, the other with alleles in a different order in the assembly.');
ok(($multiple_fastas->create_result_files),'Sort the alleles consistently and create the results files.');
compare_files($tmpdirectory.'/mlst_results.genomic.csv', 't/data/expected_sorted_mlst_results.genomic.csv', 'Spreadsheet with sequences for each matching allele for the two assemblies.');
compare_files($tmpdirectory.'/mlst_results.allele.csv', 't/data/expected_sorted_mlst_results.allele.csv', 'Spreadsheet with each matching allele number and ST for the two assemblies.');
compare_files($tmpdirectory.'/concatenated_alleles.fa', 't/data/expected_sorted_concatenated_alleles.fa', 'Create a multi-FASTA file of concatenated MLST sequences, where the alleles are in the correct order.');

sub get_sequences_from_file {

  my($FILE) = @_;

  my @sequences = ();
  my $line_number = 0;
  my $number_of_known_sequences = 0;

  while( my $line = <$FILE> ) {
    my $trimmed_line = trim($line);
    if ($number_of_known_sequences == 0) {
      # We don't know how many sequences there are so create a new one
      push( @sequences, [$trimmed_line]);
      # The first time we find a blank 'sequence' we now know the number of sequences
      if ($trimmed_line eq '') {
        $number_of_known_sequences = $line_number + 1;
      }
    } else {
      # Now that we know the number of sequences, append this line to it's corresponding sequence
      my $sequence_number = $line_number % $number_of_known_sequences;
      push( @{$sequences[$sequence_number]}, $trimmed_line);
    }
    $line_number++;
  }

  return @sequences;

}

sub compare_phylip_files {
  my($calculated_file, $expected_file) = @_;

  open(my $CALC_FILE, $calculated_file);
  open(my $EXPECTED_FILE, $expected_file);

  my $calculated_file_header = <$CALC_FILE>;
  my $expected_file_header = <$EXPECTED_FILE>;

  is($calculated_file_header, $expected_file_header, "Header matches expected value in ".$expected_file);

  my @calculated_file_sequences = sort({ $a->[0] cmp $b->[0] } get_sequences_from_file($CALC_FILE));
  my @expected_file_sequences = sort({ $a->[0] cmp $b->[0] } get_sequences_from_file($EXPECTED_FILE));

  close($CALC_FILE);
  close($EXPECTED_FILE);

  is_deeply(\@calculated_file_sequences, \@expected_file_sequences, "Sequences match ".$expected_file);

}

note('Check it can handle multiple assemblies where some have partial allele matches.');
$tmpdirectory_obj = File::Temp->newdir(DIR => getcwd, CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($multiple_fastas = Bio::MLST::Check->new(
  species               => "E.coli",
  base_directory        => 't/data/databases',
  raw_input_fasta_files => ['t/data/contigs.fa','t/data/contigs_pipe_character_in_seq_name.fa','t/data/contigs_one_unknown.tfa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  output_phylip_files   => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 3,
  report_lowest_st      => 1
)),'Pass in 3 assemblies, 2 perfect and where 1 has partial matches.');
ok(($multiple_fastas->create_result_files),'Create all the results files for three assemblies.');
compare_files( $tmpdirectory.'/mlst_results.genomic.csv',    't/data/expected_three_mlst_results.genomic.csv', 'Create a spreadsheet with the 3 sets of assemblies combined and the sequences, and give one best guess ST.' );
compare_files( $tmpdirectory.'/mlst_results.allele.csv',     't/data/expected_three_mlst_results.allele.csv', 'Create a spreadsheet with the 3 sets of assemblies combined and the allele numbers, and give one best guess ST.' );
compare_files( $tmpdirectory.'/concatenated_alleles.fa',     't/data/expected_three_concatenated_alleles.fa', 'Create a multi-FASTA file containing the concatenated sequences.');
###
compare_phylip_files( $tmpdirectory.'/concatenated_alleles.phylip', 't/data/expected_three_concatenated_alleles.phylip', 'Output the alignment of the concatenated gene sequences in phylip format, which is used as input to some tree building applications.' );
compare_files( $tmpdirectory.'/contigs_one_unknown.unknown_allele.adk-2~.fa',  't/data/expected_three_contigs_one_unknown.unknown_allele.adk-2~.fa', 'Create FASTA files for alleles which are not in the database, so that they can be added later.' );
compare_files( $tmpdirectory.'/contigs_one_unknown.unknown_allele.recA-1~.fa', 't/data/expected_three_contigs_one_unknown.unknown_allele.recA-1~.fa', 'Create FASTA files for alleles which are not in the database, so that they can be added later.' );


$tmpdirectory_obj = File::Temp->newdir(DIR => getcwd, CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($multiple_fastas = Bio::MLST::Check->new(
  species               => "E.coli",
  base_directory        => 't/data/databases',
  raw_input_fasta_files => ['t/data/contigs.fa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 1
)),'Make sure the input files exist.');
ok($multiple_fastas->input_fasta_files_exist,'Check the input FASTA file exists.');

done_testing();

sub compare_files
{
  my( $actual_file, $expected_file ) = @_;
  ok((-e $actual_file),' results file exist');
  ok((-e $expected_file)," $expected_file expected file exist");
  
  my $expected_line =  read_file($expected_file);
  my $actual_line = read_file($actual_file);
  $expected_line =~ s/ \n//gi;
  $actual_line   =~ s/ \n//gi;
  
  # parallel processes mean the order isnt guaranteed.
  my @split_expected  = split(/\n/,$expected_line);
  my @split_actual  = split(/\n/,$actual_line);
  my @sorted_expected = sort(@split_expected);
  my @sorted_actual  = sort(@split_actual);
  
  return is_deeply(\@sorted_actual, \@sorted_expected, "Content matches expected $expected_file");
}
