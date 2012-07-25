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
use MLST::Blast::Database

has 'sequence_filename' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'allele_filenames'  => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'makeblastdb_exec'  => ( is => 'ro', isa => 'Str',      required => 1 );
has 'blastn_exec'       => ( is => 'ro', isa => 'Str',      required => 1 );

has '_sequence_handle'   => ( is => 'ro', isa => 'Bio::SeqIO::fasta',           lazy => 1,  builder => '_build__sequence_handle');

has '_blast_db_location_obj' => ( is => 'ro', isa => 'MLST::Blast::Database',   lazy => 1,  builder => '_build__blast_db_location_obj');
has '_blast_db_location' => ( is => 'ro', isa => 'Str',                         lazy => 1,  builder => '_build__blast_db_location');

has 'matching_sequences'     => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_matching_sequences' );
has 'non_matching_sequences' => ( is => 'rw', isa => 'HashRef', default => sub {{}});

sub _build__blast_db_location
{
  my ($self) = @_;
  return $self->_blast_db_location_obj->location();
}

sub _build__blast_db_location_obj
{
  my ($self) = @_;
  return MLST::Blast::Database->new(fasta_file => $self->sequence_filename, exec => $self->makeblastdb_exec);
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


sub _word_size_for_given_allele_file
{
  my ($self,$filename) = @_;
  return Bio::SeqIO->new( -file => $filename , -format => 'Fasta')->next_seq()->length();
}


sub _build_matching_sequences
{
  my ($self) = @_;
  my %matching_sequence_names;
  my %non_matching_sequence_names;
  
  for my $allele_filename (@{$self->allele_filenames})
  {
    my $blast_results = MLST::Blast::BlastN->new(
      blast_database => $self->_blast_db_location,
      query_file     => $allele_filename,
      word_size      => $self->_word_size_for_given_allele_file($allele_filename),
      exec           => $self->blastn_exec
    );
    my %top_blast_hit = %{$blast_results->top_hit()};
    # TODO: no hits found - could be a deletion?
    next if(! %top_blast_hit);
    
    if($top_blast_hit{percentage_identity} == 100.0)
    {
      $matching_sequence_names{$top_blast_hit{allele_name}} = $self->_get_blast_hit_sequence($top_blast_hit{source_name}, $top_blast_hit{source_start},$top_blast_hit{source_end});
    }
    else
    {
      my $non_matching_hit_name = join('___',('similar',$top_blast_hit{allele_name},'start',$top_blast_hit{source_start},'end',$top_blast_hit{source_end},'contig',$top_blast_hit{source_name}));
      $non_matching_sequence_names{$non_matching_hit_name} = $self->_get_blast_hit_sequence($top_blast_hit{source_name}, $top_blast_hit{source_start},$top_blast_hit{source_end});
    }
  }

  $self->non_matching_sequences(\%non_matching_sequence_names);
  return \%matching_sequence_names;
}

sub _get_blast_hit_sequence
{
   my ($self, $contig_name, $start, $end) = @_;
   seek($self->_sequence_handle->_fh, 0,0);
   while( my $input_sequence_obj = $self->_sequence_handle->next_seq() ) 
   {

     next if( $input_sequence_obj->id ne $contig_name);
     return $input_sequence_obj->subseq($start, $end);
   }

   return "";
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
