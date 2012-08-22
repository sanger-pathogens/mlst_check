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

my $tmpdirectory_obj = File::Temp->newdir(CLEANUP => 1);
my $tmpdirectory = $tmpdirectory_obj->dirname();

ok((my $output_fasta = Bio::MLST::NormaliseFasta->new(
  fasta_filename    => 't/data/contigs.fa',
  working_directory => $tmpdirectory
)),'Initalise file wihtout pipe characters in sequence names');
is($output_fasta->processed_fasta_filename(),'t/data/contigs.fa', 'file without pipe characters shouldnt change at all');


ok(($output_fasta = Bio::MLST::NormaliseFasta->new(
  fasta_filename    => 't/data/contigs_pipe_character_in_seq_name.fa',
  working_directory => $tmpdirectory
)),'Initalise file with pipe characters in filename');
is($output_fasta->processed_fasta_filename(), $tmpdirectory.'/contigs_pipe_character_in_seq_name.fa', 'file without pipe characters shouldnt change at all');
ok((my $in_fasta_obj =  Bio::SeqIO->new( -file => $tmpdirectory.'/contigs_pipe_character_in_seq_name.fa' , -format => 'Fasta')), 'Open temp fasta file');
is($in_fasta_obj->next_seq()->id, '1', 'seq name now 1');
is($in_fasta_obj->next_seq()->id, '2', 'seq name now 2');
is($in_fasta_obj->next_seq()->id, '3', 'seq name now 3');
done_testing();
