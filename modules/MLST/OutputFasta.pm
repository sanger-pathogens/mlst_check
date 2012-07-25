=head1 NAME

OutputFasta - Take in two hashes, both containing sequence names and sequences and output fasta files.

=head1 SYNOPSIS

use MLST::OutputFasta;

my $output_fasta = MLST::OutputFasta->new(
  matching_sequences     => \%matching_sequences,
  non_matching_sequences => \%non_matching_sequences,
  output_directory => '/path/to/output',
  input_fasta_file => '/path/to/fasta'
);
$output_fasta->create_files();

=cut

package MLST::OutputFasta;
use Moose;
use File::Basename;
use File::Path qw(make_path);
use Bio::PrimarySeq;
use Bio::SeqIO;

has 'matching_sequences'      => ( is => 'ro', isa => 'Maybe[HashRef]',      required => 1 ); 
has 'non_matching_sequences'  => ( is => 'ro', isa => 'Maybe[HashRef]',      required => 1 ); 
has 'output_directory'        => ( is => 'ro', isa => 'Str',          required => 1 ); 
has 'input_fasta_file'        => ( is => 'ro', isa => 'Str',          required => 1 ); 

has '_fasta_filename'         => ( is => 'ro', isa => 'Str',          lazy => 1, builder => '_build__fasta_filename' ); 

sub _build__fasta_filename
{
  my($self) = @_;
  my($filename, $directories, $suffix) = fileparse($self->input_fasta_file);
  return $filename;
}

sub create_files
{
  my($self) = @_;
  make_path($self->output_directory);
  
  if($self->matching_sequences)
  {
    my $matching_output_filename = join('/',($self->output_directory, $self->_fasta_filename.'.matching.fa'));
    my $out = Bio::SeqIO->new(-file => "+>$matching_output_filename" , '-format' => 'Fasta');
    for my $sequence_name (keys %{$self->matching_sequences})
    {
      $out->write_seq(Bio::PrimarySeq->new(-seq => $self->matching_sequences->{$sequence_name}, -id  => $sequence_name));
    }
  }
  
  if($self->non_matching_sequences)
  {
    my $non_matching_output_filename = join('/',($self->output_directory, $self->_fasta_filename'.nonmatching.fa'));
    my $out = Bio::SeqIO->new(-file => "+>$non_matching_output_filename" , '-format' => 'Fasta');
    for my $sequence_name (keys %{$self->non_matching_sequences})
    {
      $out->write_seq(Bio::PrimarySeq->new(-seq => $self->non_matching_sequences->{$sequence_name}, -id  => $sequence_name));
    }
  }
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
