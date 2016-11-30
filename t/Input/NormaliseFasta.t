#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use Bio::SeqIO;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::NormaliseFasta');
}

note('Users occasionally provide FASTA files which have odd formats, so make sure these can be dealt with.');

my $tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();

ok((my $output_fasta = Bio::MLST::NormaliseFasta->new(
  fasta_filename    => 't/data/contigs.fa',
  working_directory => $tmpdirectory
)),'Pass in a FASTA file with only alphanumeric characters.');
is($output_fasta->processed_fasta_filename(),'t/data/contigs.fa', 'A FASTA file with only alphanumeric characters in the sequence names shouldnt be changed at all.');


ok(($output_fasta = Bio::MLST::NormaliseFasta->new(
  fasta_filename    => 't/data/contigs_pipe_character_in_seq_name.fa',
  working_directory => $tmpdirectory
)),'Pass in a FASTA file with pipe characters, like those found in downloads from GenBank.');
is($output_fasta->processed_fasta_filename(), $tmpdirectory.'/contigs_pipe_character_in_seq_name.fa', 'The FASTA file should be copied to a temp directory so that the sequence names can be updated without modifying the original.');
my $in_fasta_obj =  Bio::SeqIO->new( -file => $tmpdirectory.'/contigs_pipe_character_in_seq_name.fa' , -format => 'Fasta');
is($in_fasta_obj->next_seq()->id, '1', 'First sequence in modified file is now alphanumeric only.');
is($in_fasta_obj->next_seq()->id, '2', 'Second sequence in modified file is now alphanumeric only');
is($in_fasta_obj->next_seq()->id, '3', 'Third sequence in modified file is now alphanumeric only');
done_testing();
