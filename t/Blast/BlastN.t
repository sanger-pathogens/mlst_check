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

note('A wrapper around NCBI blastn which allows for a sequence to be queried against a database and the results returned in a hash.');

my $blast_database= Bio::MLST::Blast::Database->new(fasta_file => 't/data/contigs.fa');

ok((my $blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk.tfa',
   word_sizes     => word_sizes('t/data/adk.tfa')
 )), 'Setup a blast runner with a valid database and allele.');

my $fake_blast_output = <<'END_OUTPUT';
adk-1	SomeSequenceName	98.13	536	10	0	1	536	178	713	0.0	922	527
adk-2	SomeSequenceName	100.00	536	0	0	1	536	178	713	0.0	967	536
adk-3	SomeSequenceName	97.76	536	12	0	1	536	713	178	0.0	913	526
adk-4	SomeSequenceName	98.88	536	6	0	1	536	178	713	0.0	940	532
END_OUTPUT

my $blastn_line	= "adk-1	SomeSequenceName	98.13	536	10	0	1	536	178	713	0.0	922	527\n";
my %expected_hit = (
  'allele_name' => 'adk-1',
  'source_name' => 'SomeSequenceName',
  'percentage_identity' => '98.13',
  'sample_alignment_length' => '536',
  'matches' => '527',
  'source_start' => '178',
  'source_end' => '713',
  'reverse' => 0,
);
is_deeply($blastn_result->_build_hit($blastn_line), \%expected_hit, "Given a fake hit, check that its parsed into the hash correctly.");

$blastn_line	= "adk-1	SomeSequenceName	98.13	536	10	0	1	536	713	178	0.0	922	527\n";
%expected_hit = (
  'allele_name' => 'adk-1',
  'source_name' => 'SomeSequenceName',
  'percentage_identity' => '98.13',
  'sample_alignment_length' => '536',
  'matches' => '527',
  'source_start' => '178',
  'source_end' => '713',
  'reverse' => 1,
);
is_deeply($blastn_result->_build_hit($blastn_line), \%expected_hit, "Given a fake hit thats reversed, make sure the coordinates are correct.");

my $expected_hits = [
  {
    'allele_name' => 'adk-1',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.13',
    'sample_alignment_length' => '536',
    'matches' => '527',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-2',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '536',
    'matches' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-3',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '97.76',
    'sample_alignment_length' => '536',
    'matches' => '526',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 1,
  },
  {
    'allele_name' => 'adk-4',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.88',
    'sample_alignment_length' => '536',
    'matches' => '532',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
];
my $fake_blast_output_fh = new IO::Scalar \$fake_blast_output;
is_deeply($blastn_result->_build_hits($fake_blast_output_fh), $expected_hits, "Given a set of hits, extract all into a hash correctly.");

my $input_hits = [
  {
    'allele_name' => 'adk-1',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.13',
    'sample_alignment_length' => '536',
    'matches' => '527',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-2',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '436',
    'matches' => '536',
    'source_start' => '178',
    'source_end' => '613',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-3',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.88',
    'sample_alignment_length' => '336',
    'matches' => '532',
    'source_start' => '178',
    'source_end' => '513',
    'reverse' => 0,
  },
];
$expected_hits = [
  {
    'allele_name' => 'adk-1',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.13',
    'sample_alignment_length' => '536',
    'matches' => '527',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-2',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '436',
    'matches' => '536',
    'source_start' => '178',
    'source_end' => '613',
    'reverse' => 0,
  },
];
my $word_sizes = {
  'adk-1' => 500,
  'adk-2' => 436,
  'adk-3' => 400
};
is_deeply($blastn_result->_filter_by_alignment_length($input_hits, $word_sizes), $expected_hits, "Given a set of hits, filter them by alignment length to remove lower quality hits.");

$input_hits = [
  {
    'allele_name' => 'adk-1',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.13',
    'sample_alignment_length' => '536',
    'matches' => '527',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-2',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '536',
    'matches' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-3',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '97.76',
    'sample_alignment_length' => '536',
    'matches' => '526',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 1,
  },
  {
    'allele_name' => 'adk-4',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.88',
    'sample_alignment_length' => '536',
    'matches' => '532',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
];
$expected_hits = [
  {
    'allele_name' => 'adk-1',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.13',
    'sample_alignment_length' => '536',
    'matches' => '527',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-2',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '536',
    'matches' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-4',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.88',
    'sample_alignment_length' => '536',
    'matches' => '532',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
];
is_deeply($blastn_result->_filter_best_hits($input_hits), $expected_hits, "Given fake blast hits, filter out the low quality results to leave the best ones.");

$expected_hits = [
  {
    'allele_name' => 'adk-2',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '536',
    'matches' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'adk-4',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '98.88',
    'sample_alignment_length' => '536',
    'matches' => '532',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
];
is_deeply($blastn_result->_filter_best_hits($input_hits, 1.5), $expected_hits, "Given fake hits, filter out low quality results.");

my $overlapping_hits = [
  {
    'allele_name' => 'allele-1',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '536',
    'matches' => '536',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'allele-1-truncation-end',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '336',
    'matches' => '336',
    'source_start' => '178',
    'source_end' => '513',
    'reverse' => 0,
  },
  {
    'allele_name' => 'allele-1-truncation-start',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '336',
    'matches' => '336',
    'source_start' => '378',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'allele-1-truncation-middle',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '336',
    'matches' => '336',
    'source_start' => '278',
    'source_end' => '613',
    'reverse' => 0,
  },
  {
    'allele_name' => 'allele-spill-over-end',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '336',
    'matches' => '336',
    'source_start' => '478',
    'source_end' => '813',
    'reverse' => 0,
  },
  {
    'allele_name' => 'allele-completely-different-truncation',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '336',
    'matches' => '336',
    'source_start' => '1278',
    'source_end' => '1613',
    'reverse' => 0,
  },
  {
    'allele_name' => 'allele-completely-different',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '536',
    'matches' => '536',
    'source_start' => '1178',
    'source_end' => '1713',
    'reverse' => 0,
  },
];
$expected_hits = [
  {
    'start' => 178,
    'end' => 713,
    'hits' => [
      {
        'allele_name' => 'allele-1',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '536',
        'matches' => '536',
        'source_start' => '178',
        'source_end' => '713',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-1-truncation-end',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '178',
        'source_end' => '513',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-1-truncation-start',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '378',
        'source_end' => '713',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-1-truncation-middle',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '278',
        'source_end' => '613',
        'reverse' => 0,
      },
    ],
  },
  {
    'start' => 478,
    'end' => 813,
    'hits' => [
      {
        'allele_name' => 'allele-spill-over-end',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '478',
        'source_end' => '813',
        'reverse' => 0,
      },
    ],
  },
  {
    'start' => 1178,
    'end' => 1713,
    'hits' => [
      {
        'allele_name' => 'allele-completely-different-truncation',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '1278',
        'source_end' => '1613',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-completely-different',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '536',
        'matches' => '536',
        'source_start' => '1178',
        'source_end' => '1713',
        'reverse' => 0,
      },
    ],
  },
];
is_deeply($blastn_result->_group_overlapping_hits($overlapping_hits), $expected_hits, "Group overlapping blast hits because they are often split up over the same gene.");

my $bins = [
  {
    'start' => 178,
    'end' => 713,
    'hits' => [
      {
        'allele_name' => 'allele-1-truncation-middle',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '278',
        'source_end' => '613',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-1',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '536',
        'matches' => '536',
        'source_start' => '178',
        'source_end' => '713',
        'reverse' => 0,
      },
    ],
  },
  {
    'start' => 478,
    'end' => 1013,
    'hits' => [
      {
        'allele_name' => 'allele-some-overlap',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '478',
        'source_end' => '1013',
        'reverse' => 0,
      },
    ],
  },
  {
    'start' => 180,
    'end' => 715,
    'hits' => [
      {
        'allele_name' => 'allele-lots-of-overlap',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '536',
        'matches' => '536',
        'source_start' => '180',
        'source_end' => '715',
        'reverse' => 0,
      },
    ],
  },
];
my $merged_bins = [
  {
    'start' => 178,
    'end' => 715,
    'hits' => [
      {
        'allele_name' => 'allele-1-truncation-middle',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '278',
        'source_end' => '613',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-1',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '536',
        'matches' => '536',
        'source_start' => '178',
        'source_end' => '713',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-lots-of-overlap',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '536',
        'matches' => '536',
        'source_start' => '180',
        'source_end' => '715',
        'reverse' => 0,
      },
    ],
  },
  {
    'start' => 478,
    'end' => 1013,
    'hits' => [
      {
        'allele_name' => 'allele-some-overlap',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '478',
        'source_end' => '1013',
        'reverse' => 0,
      },
    ],
  },
];
is_deeply($blastn_result->_merge_similar_bins($bins), $merged_bins, "Merge hits on a the same genes so that they form bigger hits.");

$bins = [
  {
    'start' => 178,
    'end' => 715,
    'hits' => [
      {
        'allele_name' => 'allele-1-truncation-middle',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '278',
        'source_end' => '613',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-1',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '536',
        'matches' => '536',
        'source_start' => '178',
        'source_end' => '713',
        'reverse' => 0,
      },
      {
        'allele_name' => 'allele-lots-of-overlap',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '536',
        'matches' => '536',
        'source_start' => '180',
        'source_end' => '715',
        'reverse' => 0,
      },
    ],
  },
  {
    'start' => 478,
    'end' => 1013,
    'hits' => [
      {
        'allele_name' => 'allele-some-overlap',
        'source_name' => 'SomeSequenceName',
        'percentage_identity' => '100.00',
        'sample_alignment_length' => '336',
        'matches' => '336',
        'source_start' => '478',
        'source_end' => '1013',
        'reverse' => 0,
      },
    ],
  },
];
my $groups = [
  [
    {
      'allele_name' => 'allele-1-truncation-middle',
      'source_name' => 'SomeSequenceName',
      'percentage_identity' => '100.00',
      'sample_alignment_length' => '336',
      'matches' => '336',
      'source_start' => '278',
      'source_end' => '613',
      'reverse' => 0,
    },
    {
      'allele_name' => 'allele-1',
      'source_name' => 'SomeSequenceName',
      'percentage_identity' => '100.00',
      'sample_alignment_length' => '536',
      'matches' => '536',
      'source_start' => '178',
      'source_end' => '713',
      'reverse' => 0,
    },
    {
      'allele_name' => 'allele-lots-of-overlap',
      'source_name' => 'SomeSequenceName',
      'percentage_identity' => '100.00',
      'sample_alignment_length' => '536',
      'matches' => '536',
      'source_start' => '180',
      'source_end' => '715',
      'reverse' => 0,
    },
  ],
  [
    {
      'allele_name' => 'allele-some-overlap',
      'source_name' => 'SomeSequenceName',
      'percentage_identity' => '100.00',
      'sample_alignment_length' => '336',
      'matches' => '336',
      'source_start' => '478',
      'source_end' => '1013',
      'reverse' => 0,
    },
  ],
];
is_deeply($blastn_result->_bins_to_groups($bins), $groups, "Convert sets of hits into summerised groups of hits over an allele.");

$input_hits = [
  {
    'allele_name' => 'allele-1',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '90.00',
    'sample_alignment_length' => '536',
    'matches' => '484',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
  {
    'allele_name' => 'allele-1-truncation-end',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '100.00',
    'sample_alignment_length' => '336',
    'matches' => '336',
    'source_start' => '178',
    'source_end' => '513',
    'reverse' => 0,
  },
  {
    'allele_name' => 'allele-2',
    'source_name' => 'SomeSequenceName',
    'percentage_identity' => '95.00',
    'sample_alignment_length' => '536',
    'matches' => '511',
    'source_start' => '178',
    'source_end' => '713',
    'reverse' => 0,
  },
];
my $expected_hit = {
  'allele_name' => 'allele-2',
  'source_name' => 'SomeSequenceName',
  'percentage_identity' => '95.00',
  'sample_alignment_length' => '536',
  'matches' => '511',
  'source_start' => '178',
  'source_end' => '713',
  'reverse' => 0,
};
is_deeply($blastn_result->_best_hit_in_group($input_hits), $expected_hit, "Report the best match in the group based.");

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk.tfa',
   word_sizes     => word_sizes('t/data/adk.tfa')
 )), 'Prepare the blast hits with perfect data.');
is_deeply($blastn_result->top_hit, {allele_name => 'adk-2', percentage_identity => 100, source_name => 'SomeSequenceName', source_start => 178, source_end => 713, reverse => 0 }, 'An exact match to an allele of full length should be the best hit.');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_contamination.tfa',
   word_sizes     => word_sizes('t/data/adk_contamination.tfa')
 )), 'Prepare the blast hits with some contamination.');
ok(defined($blastn_result->top_hit->{contamination}), 'Contamination should be flagged');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_truncation.tfa',
   word_sizes     => word_sizes('t/data/adk_truncation.tfa')
 )), 'Prepare the blast hits with a truncated gene.');
ok((! defined($blastn_result->top_hit->{contamination})), 'Contamination not detected where one allele is a truncation of another');
is($blastn_result->top_hit->{allele_name}, 'adk-3', 'Picks longer allele if one allele is a truncation of another');

my $blast_database_near_match= Bio::MLST::Blast::Database->new(fasta_file => 't/data/contigs_near_match.fa');
ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database_near_match->location(),
   query_file     => 't/data/adk_top_hit_low_hit.tfa',
   word_sizes     => word_sizes('t/data/adk_top_hit_low_hit.tfa')
 )), 'Prepare the blast hits where there are multiple close matches');

is($blastn_result->top_hit->{allele_name}, 'adk-2', 'Correct allele found out of multiple hits');
is($blastn_result->top_hit->{percentage_identity}, 100,'Correct allele found out of multiple hits');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_99_percent.tfa',
   word_sizes     => word_sizes('t/data/adk_99_percent.tfa')
 )), 'Prepare the blast hits when there is a 99% match');

is($blastn_result->top_hit->{allele_name}, 'adk-2', 'Correct allele close match');
is($blastn_result->top_hit->{percentage_identity}, 99,'Correct allele close match');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_less_than_95_percent.tfa',
   word_sizes     => word_sizes('t/data/adk_less_than_95_percent.tfa')
 )), 'Prepare the blast hits where the match is less than 95% of any existing allele.');

is_deeply($blastn_result->top_hit, {}, 'Report no hits found if the hits are less than 95%.');

ok(($blastn_result = Bio::MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk.tfa', # << ignore this, not used
   word_sizes     => {
                       'gdh_18'  => 460,
                       'gdh_9'   => 460,
                       'gdh_325' => 460,
                       'gdh_32'  => 460,
                     },
   'exec'         => 't/data/gdh_fake_blast_output.sh' # ignores arguments and outputs some fake output to stdout
 )), 'Check overlapping reads.');
ok(!defined($blastn_result->top_hit->{contamination}), 'Contamination not detected for mostly overlapping alleles');


# Exec not available
dies_ok( sub {
  Bio::MLST::Blast::BlastN->new(
    blast_database => $blast_database->location(),
    query_file     => 't/data/adk.tfa',
    word_sizes     => {},
    exec           => 'non_existant_executable'
  );
}, 'Validate if the executable is available');

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
