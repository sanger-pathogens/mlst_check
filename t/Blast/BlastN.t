#!/usr/bin/env perl
use strict;
use warnings;
use Bio::SeqIO;
use File::Temp;
use IO::Scalar;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use Bio::MLST::Blast::Database;
    use_ok('Bio::MLST::Blast::BlastN');
}

my $blast_database= Bio::MLST::Blast::Database->new(fasta_file => 't/data/contigs.fa');

ok((my $blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk.tfa',
   word_sizes     => word_sizes('t/data/adk.tfa')
 )), 'initialise valid blastN');

my $fake_blast_output = <<'END_OUTPUT';
adk-1	SomeSequenceName	98.13	536	10	0	1	536	178	713	0.0	922
adk-2	SomeSequenceName	100.00	536	0	0	1	536	178	713	0.0	967
adk-3	SomeSequenceName	97.76	536	12	0	1	536	713	178	0.0	913
adk-4	SomeSequenceName	98.88	536	6	0	1	536	178	713	0.0	940
END_OUTPUT

my $blastn_line	= "adk-1	SomeSequenceName	98.13	536	10	0	1	536	178	713	0.0	922\n";
my %expected_hit = (
  'allele_name' => 'adk-1',
  'source_name' => 'SomeSequenceName',
  'percentage_identity' => '98.13',
  'alignment_length' => '536',
  'source_start' => '178',
  'source_end' => '713',
  'reverse' => 0,
);
is_deeply($blastn_result->_build_hit($blastn_line), \%expected_hit, "extract one hit");

$blastn_line	= "adk-1	SomeSequenceName	98.13	536	10	0	1	536	713	178	0.0	922\n";
%expected_hit = (
  'allele_name' => 'adk-1',
  'source_name' => 'SomeSequenceName',
  'percentage_identity' => '98.13',
  'alignment_length' => '536',
  'source_start' => '178',
  'source_end' => '713',
  'reverse' => 1,
);
is_deeply($blastn_result->_build_hit($blastn_line), \%expected_hit, "extract one reverse hit");

my $expected_hits = [
  {
    'allele_name' => 'adk-1',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.13',
    'alignment_length' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-2',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'alignment_length' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-3',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '97.76',
    'alignment_length' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 1,
  },
  {
    'allele_name' => 'adk-4',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.88',
    'alignment_length' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
];
my $fake_blast_output_fh = new IO::Scalar \$fake_blast_output;
is_deeply($blastn_result->_build_hits($fake_blast_output_fh), $expected_hits, "extract array of hits");

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk.tfa',
   word_sizes     => word_sizes('t/data/adk.tfa')
 )), 'initialise valid blastN');
is_deeply($blastn_result->top_hit, {allele_name => 'adk-2', percentage_identity => 100, source_name => 'SomeSequenceName', source_start => 178, source_end => 713, reverse => 0 }, 'Hit correctly returned');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_contamination.tfa',
   word_sizes     => word_sizes('t/data/adk_contamination.tfa')
 )), 'initialise valid blastN with contamination');
ok(defined($blastn_result->top_hit->{contamination}), 'contamination detected');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_truncation.tfa',
   word_sizes     => word_sizes('t/data/adk_truncation.tfa')
 )), 'initialise valid blastN with contamination');
ok((! defined($blastn_result->top_hit->{contamination})), 'contamination not detected where one allele is a truncation of another');
is($blastn_result->top_hit->{allele_name}, 'adk-3', 'picks longer allele if one allele is a truncation of another');

my $blast_database_near_match= Bio::MLST::Blast::Database->new(fasta_file => 't/data/contigs_near_match.fa');
ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database_near_match->location(),
   query_file     => 't/data/adk_top_hit_low_hit.tfa',
   word_sizes     => word_sizes('t/data/adk_top_hit_low_hit.tfa')
 )), 'initialise valid blastN with multiple close matches');

is($blastn_result->top_hit->{allele_name}, 'adk-2', 'correct allele found out of multiple hits');
is($blastn_result->top_hit->{percentage_identity}, 100,'correct allele found out of multiple hits');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_99_percent.tfa',
   word_sizes     => word_sizes('t/data/adk_99_percent.tfa')
 )), 'initialise valid blastN 99% match');

is($blastn_result->top_hit->{allele_name}, 'adk-2', 'correct allele close match');
is($blastn_result->top_hit->{percentage_identity}, 99,'correct allele close match');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_less_than_95_percent.tfa',
   word_sizes     => word_sizes('t/data/adk_less_than_95_percent.tfa')
 )), 'initialise valid blastN with very low hit');

is_deeply($blastn_result->top_hit, {}, 'no hits found');


# Exec not available
dies_ok( sub {
  Bio::MLST::Blast::BlastN->new(
    blast_database => $blast_database->location(),
    query_file     => 't/data/adk.tfa',
    word_sizes     => {},
    exec           => 'non_existant_executable'
  );
}, 'Validate if the exec is available');

sub word_sizes {
  my $filename = shift;

  my %seq_lens;
  my $seqio = Bio::SeqIO->new( -file => $filename , -format => 'Fasta');
  while( my $seq = $seqio->next_seq() ){
    $seq_lens{$seq->primary_id} = $seq->length;
  }
  return \%seq_lens;
}

done_testing();
