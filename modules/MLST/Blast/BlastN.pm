=head1 NAME

BlastN - Take in a fasta file and create a temporary blast database

=head1 SYNOPSIS

use MLST::Blast::BlastN;

my $blast_database= MLST::Blast::BlastN->new(
  blast_database => 'output_contigs',
  query_file     => 'alleles/adk.tfa',
  word_size      => 500,
  exec           => 'blastn'
);

$blast_database->top_hit();

=cut

package MLST::Blast::BlastN;
use Moose;
use File::Temp;

# input variables
has 'blast_database'     => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'query_file'         => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'word_size'          => ( is => 'ro', isa => 'Int', required => 1 ); 
has 'exec'               => ( is => 'ro', isa => 'Str', required => 1 ); 

# Generated

has 'top_hit'           => ( is => 'ro', isa => 'Maybe[HashRef]', lazy => 1,  builder => '_build_top_hit' ); 

sub _blastn_cmd
{
  my($self) = @_;
  join(' ',($self->exec, '-task blastn', '-query', $self->query_file, '-db', $self->blast_database, '-outfmt 6', '-word_size', $self->word_size ));
}

sub _build_top_hit
{
  my($self) = @_;
  open( my $blast_output_fh, '-|',$self->_blastn_cmd);
  my $highest_identity = 0;
  my %top_hit;
  
  while(<$blast_output_fh>)
  {
    chomp;
    my $line = $_;
    my @blast_raw_results = split(/\t/,$line);
    if($blast_raw_results[2] > $highest_identity)
    {
      $top_hit{allele_name} = $blast_raw_results[0];
      $top_hit{percentage_identity} = $blast_raw_results[2];
      $top_hit{source_name} = $blast_raw_results[1];
      
      my $start  = $blast_raw_results[8]
      my $end  = $blast_raw_results[9];
      if($start > $end)
      {
        my $tmp = $start;
        $start = $end;
        $end = $tmp;
      }
      
      $top_hit{source_start} = $start;
      $top_hit{source_end} = $end;
      $highest_identity = $blast_raw_results[2];
    }
  }
  return \%top_hit;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
