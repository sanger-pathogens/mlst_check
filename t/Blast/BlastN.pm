#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './modules') }
BEGIN {
    use Test::Most;
    use MLST::Blast::Database;
    use_ok('MLST::Blast::BlastN');
}

my $blast_database= MLST::Blast::Database->new(fasta_file => 't/data/contigs.fa');

ok((my $blastn_result = MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk.tfa',
   word_size      => 536
 )), 'initialise valid blastN');
is_deeply($blastn_result->top_hit, {allele_name => 'adk-2', percentage_identity => 100, source_name => 'SomeSequenceName', source_start => 178, source_end => 713 }, 'Hit correctly returned');

ok(($blastn_result = MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_contamination.tfa',
   word_size      => 536
 )), 'initialise valid blastN with contamination');
ok(defined($blastn_result->top_hit->{contamination}), 'contamination detected');

ok(($blastn_result = MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_top_hit_low_hit.tfa',
   word_size      => 100
 )), 'initialise valid blastN with multiple close matches');

is($blastn_result->top_hit->{allele_name}, 'adk-2', 'correct allele found out of multiple hits');
is($blastn_result->top_hit->{percentage_identity}, 100,'correct allele found out of multiple hits');

ok(($blastn_result = MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_99_percent.tfa',
   word_size      => 500
 )), 'initialise valid blastN 99% match');

is($blastn_result->top_hit->{allele_name}, 'adk-2', 'correct allele close match');
is($blastn_result->top_hit->{percentage_identity}, 99,'correct allele close match');

ok(($blastn_result = MLST::Blast::BlastN->new(
   blast_database => $blast_database->location(),
   query_file     => 't/data/adk_less_than_95_percent.tfa',
   word_size      => 536
 )), 'initialise valid blastN with very low hit');

is_deeply($blastn_result->top_hit, {}, 'no hits found');


# Exec not available
dies_ok( sub {
  MLST::Blast::BlastN->new(
    blast_database => $blast_database->location(),
    query_file     => 't/data/adk.tfa',
    word_size      => 536,
    exec           => 'non_existant_executable'
  );
}, 'Validate if the exec is available');



done_testing();
