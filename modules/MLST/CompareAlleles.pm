=head1 NAME

CompareAlleles - Take in an assembly file in Fasta format, and a list of allele files (in multifasta format) and return a list of the alleles and IDs.

=head1 SYNOPSIS

use MLST::CompareAlleles;

my $compare_alleles = MLST::CompareAlleles->new(

  sequence_filename => 'contigs.fa',
  allele_filenames => ['abc.tfa','efg.tfa']
);
$compare_alleles->found_sequence_names;
$compare_alleles->matching_sequences;
=cut

package MLST::CompareAlleles;
use Moose;
use Bio::SeqIO;

has 'sequence_filename' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'allele_filenames'  => ( is => 'ro', isa => 'ArrayRef', required => 1 );

has '_sequence_handle'  => ( is => 'ro', isa => 'Bio::SeqIO::fasta',           lazy => 1,  builder => '_build__sequence_handle');
has '_allele_handles'   => ( is => 'ro', isa => 'ArrayRef[Bio::SeqIO::fasta]', lazy => 1,  builder => '_build__allele_handles' );

has 'matching_sequences'   => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_matching_sequences' );

sub _build__allele_handles
{
  my ($self) = @_;
  my @allele_handles;
  for my $allele_file (@{$self->allele_filenames})
  {
    push(@allele_handles, Bio::SeqIO->new( -file => $allele_file , -format => 'Fasta'));
  }
  return \@allele_handles;
}

sub _build__sequence_handle
{
  my ($self) = @_;
  return Bio::SeqIO->new( -file => $self->sequence_filename , -format => 'Fasta');
}

sub found_sequence_names
{
  my ($self) = @_;
  my @sequence_names = sort(keys %{$self->matching_sequences});
  return \@sequence_names;
}

sub _build_matching_sequences
{
  my ($self) = @_;
  my %matching_sequence_names;
  
  while( my $input_sequence_obj = $self->_sequence_handle->next_seq() ) 
  {
    my $input_sequence = $input_sequence_obj->seq();
    
    for my $allele_handle (@{$self->_allele_handles})
    {
      seek($allele_handle->_fh,0,0);
      
      while(my $allele_sequence_obj = $allele_handle->next_seq() )
      {
        my $allele_sequence = $allele_sequence_obj->seq();
        if( $input_sequence =~ m/$allele_sequence/)
        {
          $matching_sequence_names{$allele_sequence_obj->id} = $allele_sequence;
          last;
        }
      }
    }
    
  }
  return \%matching_sequence_names;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
