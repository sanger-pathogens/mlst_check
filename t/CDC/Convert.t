#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use Bio::MLST::Check;
    use_ok('Bio::MLST::CDC::Convert');
}

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

# take in a fasta file, split it into alleles and profile
ok((my $convert_fasta = Bio::MLST::CDC::Convert->new(
  species        => 'Streptococcus pyogenes emmST',
  input_file     => 't/data/CDC_emmST_partial.tfa',
  gene_name      => 'emmST',
  base_directory => $destination_directory
  )),'initialise the converter');

ok(($convert_fasta->create_mlst_files), 'Create the files');
ok((-d $destination_directory.'/Streptococcus_pyogenes_emmST'), 'should create the organism directory');
ok((-e $destination_directory.'/Streptococcus_pyogenes_emmST/alleles/emmST.tfa'), 'should create an allele fasta file');
ok((-e $destination_directory.'/Streptococcus_pyogenes_emmST/profiles/Streptococcus_pyogenes_emmST.txt'), 'Should create the profile text file');

compare_files('t/data/Streptococcus_pyogenes_emmST/alleles/emmST.tfa', $destination_directory.'/Streptococcus_pyogenes_emmST/alleles/emmST.tfa');
compare_files('t/data/Streptococcus_pyogenes_emmST/profiles/Streptococcus_pyogenes_emmST.txt', $destination_directory.'/Streptococcus_pyogenes_emmST/profiles/Streptococcus_pyogenes_emmST.txt' );


# Check the the converted files can be used
my $tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();

ok((my $check_converted_files_obj = Bio::MLST::Check->new(
  species               => "Streptococcus pyogenes emmST",
  base_directory        => $destination_directory,
  raw_input_fasta_files => ['t/data/Streptococcus_pyogenes_emmST_contigs.fa'],
  makeblastdb_exec      => 'makeblastdb',
  blastn_exec           => 'blastn',
  output_directory      => $tmpdirectory,
  output_fasta_files    => 1,
  spreadsheet_basename  => 'mlst_results',
  parallel_processes    => 1,
  show_contamination_instead_of_alt_matches => 0,
)),'Pass in the converted files and perform a lookup');
ok(($check_converted_files_obj->create_result_files),'create all the results files for the fasta');

compare_files('t/data/expected_Streptococcus_pyogenes_emmST.genomic.csv', $tmpdirectory.'/mlst_results.genomic.csv');
compare_files('t/data/expected_Streptococcus_pyogenes_emmST.allele.csv', $tmpdirectory.'/mlst_results.allele.csv');
compare_files('t/data/expected_Streptococcus_pyogenes_emmST_alleles.fa', $tmpdirectory.'/concatenated_alleles.fa');


ok((my $convert_fasta_ftp = Bio::MLST::CDC::Convert->new(
  species        => 'Streptococcus pyogenes emmST',
  input_file     => 'ftp://example.com/file.fa',
  gene_name      => 'emmST',
  base_directory => $destination_directory
  )),'initialise the converter with remote url');
ok(($convert_fasta_ftp->input_file), 'remote url was accepted');


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