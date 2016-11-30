#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::CheckMultipleSpecies');
}
note('Check you can search input assemblies against multiple MLST databases as the same time.');
my $tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();


ok((my $multi_mlst_A = Bio::MLST::CheckMultipleSpecies->new( species               => ['E.coli','H.pylori'],
							     base_directory        => 't/data/databases',
							     raw_input_fasta_files => ['t/data/contigs.fa'],
							     makeblastdb_exec      => 'makeblastdb',
							     blastn_exec           => 'blastn',
							     output_directory      => $tmpdirectory ,
							     spreadsheet_basename  => 'multi_mlst_results',
							     parallel_processes    => 2,
							     output_fasta_files    => 0,
							     output_phylip_files   => 0,
							     verbose               => 0)),'For a single assembly lookup two different MLST databases at once.');
							     
ok(($multi_mlst_A->create_result_files),'Create the output file set.');
compare_files('t/data/expected_multi_mlst_results.allele.csv', $tmpdirectory.'/multi_mlst_results.allele.csv', 'There should be full allele numbers and an ST for one of the databases and partial for the other.');
compare_files('t/data/expected_multi_mlst_results.genomic.csv',$tmpdirectory.'/multi_mlst_results.genomic.csv', 'There should be full allele sequences and an ST for one of the databases and partial for the other.');

ok((my $multi_mlst_B = Bio::MLST::CheckMultipleSpecies->new( species               => [],
							     base_directory        => 't/data/databases',
							     raw_input_fasta_files => ['t/data/contigs.fa','nonexist.fa'],
							     makeblastdb_exec      => 'makeblastdb',
							     blastn_exec           => 'blastn',
							     output_directory      => $tmpdirectory ,
							     spreadsheet_basename  => 'multi_mlst_results',
							     parallel_processes    => 2,
							     output_fasta_files    => 1,
							     output_phylip_files   => 1,
							     verbose               => 0)),'Pass in 2 assemblies, where one is valid, and the other invalid and lookup all MLST databases.');

open(my $copy_stdout, ">&STDOUT"); open(STDOUT, '>/dev/null'); # redirect stdout
my $input_file_test   = $multi_mlst_B->_check_input_files_exist;
my $input_option_test = $multi_mlst_B->_check_fasta_phylip_options;
close(STDOUT); open(STDOUT, ">&", $copy_stdout); # restore stdout

ok(!$input_file_test,'The non-existant file should be flagged.');

ok(!$input_option_test,'The output FASTA and PHYLIP options shouldnt give anything because the input is non-existant.');

is_deeply(['Escherichia_coli_1', 'Helicobacter_pylori', 'Streptococcus_pyogenes', 'Streptococcus_pyogenes_emmST'], $multi_mlst_B->_species_list,'Listing out all the species available should always work, even if the input file doesnt exist.');

done_testing();

sub compare_files
{
  my($expected_file, $actual_file) = @_;
  ok((-e $actual_file),  "results file exists  - $actual_file");
  ok((-e $expected_file),"expected file exists - $expected_file");
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
  
  is_deeply(\@sorted_expected,\@sorted_actual, "results content matches expected content");
}
