#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::OutputFasta');
}

note('Check that when you have unknown alleles that FASTA files are created for each so that they can be fed back into the databases, and assigned new allele numbers.');

my $tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();
ok((my $output_fasta = Bio::MLST::OutputFasta->new(
  matching_sequences     => {'adk-2' => "AAAA", 'purA-3' => "CCCC"},
  non_matching_sequences => {},
  output_directory => $tmpdirectory,
  input_fasta_file => 't/data/contigs.fa'
)), "There are no new alleles so business as usual.");
ok(($output_fasta->create_files()),'Created output files where there no new alleles.');
ok( ! -e $tmpdirectory."/contigs.unknown_allele.adk-2.fa", 'No FASTA file created for known allele.');

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($output_fasta = Bio::MLST::OutputFasta->new(
  matching_sequences     => {},
  non_matching_sequences => {},
  output_directory => $tmpdirectory,
  input_fasta_file => 't/data/contigs.fa'
)), "The assembly contains no matching alleles at all.");
ok(($output_fasta->create_files()),'Created output files where there are no matching alleles of any kind.');
ok(!(-e $tmpdirectory."/contigs.mlst_loci.fa"), 'No output files created, because there were none matching.');

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($output_fasta = Bio::MLST::OutputFasta->new(
  matching_sequences     => { 'purA-3' => "CCCC", 'adk-2' => "AAAA"},
  non_matching_sequences => {'EEE' => "GGGG",'FFF' => "TTTT"},
  output_directory => $tmpdirectory,
  input_fasta_file => 't/data/contigs.fa'
)), "The assembly has both matching and non-matching alleles.");
ok(($output_fasta->create_files()),'Created output files where there is a mixture of matching and non-matching alleles.');
compare_file_content($tmpdirectory."/contigs.unknown_allele.EEE.fa", '>EEE
GGGG
', 'FASTA file containing new unknown allele has been created');
compare_file_content($tmpdirectory."/contigs.unknown_allele.FFF.fa", '>FFF
TTTT
', 'FASTA file containing new unknown allele has been created');
ok( ! -e $tmpdirectory."/contigs.unknown_allele.adk-2.fa", 'No FASTA file created for known allele.');
ok( ! -e $tmpdirectory."/contigs.unknown_allele.purA-3.fa", 'No FASTA file created for known allele.');

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($output_fasta = Bio::MLST::OutputFasta->new(
  matching_sequences     => { 'purA-3' => "CCCC", 'adk-2' => "AAAA"},
  non_matching_sequences => {'EEE' => "NNNN",'FFF' => "TTTT"},
  output_directory => $tmpdirectory,
  input_fasta_file => 't/data/contigs.fa'
)), "The assembly contains new alleles plus one that is too far away from pre-existing alleles.");
ok(($output_fasta->create_files()),'Created output files where there is a mix of near and far new alleles.');
ok(!(-e $tmpdirectory."/contigs.unknown_allele.EEE.fa"), 'No output files created for unknown loci because its all Ns.');
compare_file_content($tmpdirectory."/contigs.unknown_allele.FFF.fa", '>FFF
TTTT
', 'FASTA file containing new unknown allele has been created');

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($output_fasta = Bio::MLST::OutputFasta->new(
  matching_sequences     => { 'purA-3' => "CCCC", 'adk-2' => "AAAA"},
  non_matching_sequences => {'EEE' => "GGNN",'FFF' => "TTTT"},
  output_directory => $tmpdirectory,
  input_fasta_file => 't/data/contigs.fa'
)), "One of the matching new alleles has partial missing data, so is truncated.");
ok(($output_fasta->create_files()),'Created output files where one of the new alleles is truncated.');
compare_file_content($tmpdirectory."/contigs.unknown_allele.EEE.fa", '>EEE
GGNN
','The FASTA file of the unknown sequence should still be created,even when the sequence is truncated.');
compare_file_content($tmpdirectory."/contigs.unknown_allele.FFF.fa", '>FFF
TTTT
','FASTA file containing new unknown allele has been created');

done_testing();

sub compare_file_content
{
  my($input_file, $expected_string) = @_;
  ok((-e $input_file), 'Input file exists');
  local $/ = undef;
  open(my $fh, '<',$input_file) or die "Couldnt open file $input_file\n";
  my $actual_string = <$fh>;
  chomp($actual_string);
  is( $expected_string,$actual_string, 'input file matches expect string' );
}
