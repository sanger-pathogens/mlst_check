#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::CheckMultipleSpecies');
}

my $tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();

# valid instance
ok((my $multi_mlst_A = Bio::MLST::CheckMultipleSpecies->new( species               => ['E.coli','H.pylori'],
							     base_directory        => 't/data',
							     raw_input_fasta_files => ['t/data/contigs.fa'],
							     makeblastdb_exec      => 'makeblastdb',
							     blastn_exec           => 'blastn',
							     output_directory      => $tmpdirectory ,
							     spreadsheet_basename  => 'multi_mlst_results',
							     parallel_processes    => 2,
							     output_fasta_files    => 0,
							     output_phylip_files   => 0,
							     verbose               => 0)),'initialise valid');
# valid instance produces expected files
ok(($multi_mlst_A->create_result_files),'mlst for valid instance');
compare_files('t/data/expected_multi_mlst_results.allele.csv', $tmpdirectory.'/multi_mlst_results.allele.csv');
compare_files('t/data/expected_multi_mlst_results.genomic.csv',$tmpdirectory.'/multi_mlst_results.genomic.csv');

# invalid instance
ok((my $multi_mlst_B = Bio::MLST::CheckMultipleSpecies->new( species               => [],
							     base_directory        => 't/data',
							     raw_input_fasta_files => ['t/data/contigs.fa','nonexist.fa'],
							     makeblastdb_exec      => 'makeblastdb',
							     blastn_exec           => 'blastn',
							     output_directory      => $tmpdirectory ,
							     spreadsheet_basename  => 'multi_mlst_results',
							     parallel_processes    => 2,
							     output_fasta_files    => 1,
							     output_phylip_files   => 1,
							     verbose               => 0)),'initialise invalid');

# redirect stdout and check input errors
open(my $copy_stdout, ">&STDOUT"); open(STDOUT, '>/dev/null'); # redirect stdout
my $input_file_test   = $multi_mlst_B->_check_input_files_exist;
my $input_option_test = $multi_mlst_B->_check_fasta_phylip_options;
close(STDOUT); open(STDOUT, ">&", $copy_stdout); # restore stdout

# check for nonexist fasta
ok(!$input_file_test,'input file check');

# check for fasta + phylip option
ok(!$input_option_test,'options check');

# list all species
ok(('Escherichia_coli_1,Helicobacter_pylori' eq join(',',@{$multi_mlst_B->_species_list})),'species list');

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
