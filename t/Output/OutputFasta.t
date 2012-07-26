#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './modules') }
BEGIN {
    use Test::Most;
    use_ok('MLST::OutputFasta');
}

my $tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();

ok((my $output_fasta = MLST::OutputFasta->new(
  matching_sequences     => {'adk-2' => "AAAA", 'purA-3' => "CCCC"},
  non_matching_sequences => {},
  output_directory => $tmpdirectory,
  input_fasta_file => '/path/to/myfasta.fa'
)), "Initialise matching seq");
ok(($output_fasta->create_files()),'created output files');
compare_file_content($tmpdirectory."/myfasta.mlst_loci.fa", ">myfasta
AAAACCCC
");

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($output_fasta = MLST::OutputFasta->new(
  matching_sequences     => {},
  non_matching_sequences => {},
  output_directory => $tmpdirectory,
  input_fasta_file => '/path/to/myfasta.fa'
)), "Initialise no matching seq");
ok(($output_fasta->create_files()),'created output files');
ok(!(-e $tmpdirectory."/myfasta.mlst_loci.fa"), 'No output files created');

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($output_fasta = MLST::OutputFasta->new(
  matching_sequences     => { 'purA-3' => "CCCC", 'adk-2' => "AAAA"},
  non_matching_sequences => {'EEE' => "GGGG",'FFF' => "TTTT"},
  output_directory => $tmpdirectory,
  input_fasta_file => '/path/to/myfasta.fa'
)), "Initialise matching and non matching");
ok(($output_fasta->create_files()),'created output files');
compare_file_content($tmpdirectory."/myfasta.mlst_loci.fa", ">myfasta
AAAACCCCGGGGTTTT
");
compare_file_content($tmpdirectory."/myfasta.unknown_locus.EEE.fa", '>EEE
GGGG
');
compare_file_content($tmpdirectory."/myfasta.unknown_locus.FFF.fa", '>FFF
TTTT
');

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($output_fasta = MLST::OutputFasta->new(
  matching_sequences     => { 'purA-3' => "CCCC", 'adk-2' => "AAAA"},
  non_matching_sequences => {'EEE' => "NNNN",'FFF' => "TTTT"},
  output_directory => $tmpdirectory,
  input_fasta_file => '/path/to/myfasta.fa'
)), "Initialise non matching with an unknown sequence");
ok(($output_fasta->create_files()),'created output files');
compare_file_content($tmpdirectory."/myfasta.mlst_loci.fa", ">myfasta
AAAACCCCNNNNTTTT
");
ok(!(-e $tmpdirectory."/myfasta.unknown_locus.EEE.fa"), 'No output files created for unknown loci');
compare_file_content($tmpdirectory."/myfasta.unknown_locus.FFF.fa", '>FFF
TTTT
');

$tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
$tmpdirectory = $tmpdirectory_obj->dirname();
ok(($output_fasta = MLST::OutputFasta->new(
  matching_sequences     => { 'purA-3' => "CCCC", 'adk-2' => "AAAA"},
  non_matching_sequences => {'EEE' => "GGNN",'FFF' => "TTTT"},
  output_directory => $tmpdirectory,
  input_fasta_file => '/path/to/myfasta.fa'
)), "Initialise non matching has a short sequence");
ok(($output_fasta->create_files()),'created output files');
compare_file_content($tmpdirectory."/myfasta.mlst_loci.fa", ">myfasta
AAAACCCCGGNNTTTT
");
compare_file_content($tmpdirectory."/myfasta.unknown_locus.EEE.fa", '>EEE
GGNN
');
compare_file_content($tmpdirectory."/myfasta.unknown_locus.FFF.fa", '>FFF
TTTT
');

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