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
has 'concat_sequence'         => ( is => 'rw', isa => 'Maybe[Str]' );


sub _build__fasta_filename
{
  my($self) = @_;
  my $filename  = fileparse($self->input_fasta_file, qr/\.[^.]*$/);
  return $filename;
}

sub _sort_and_join_sequences
{
  my($self, $combined_sequences) = @_;
  join("",sort(values(%{$combined_sequences})));
}

sub create_files
{
  my($self) = @_;
  make_path($self->output_directory);
  $self->_fasta_filename;
  if(defined($self->matching_sequences) && %{$self->matching_sequences})
  {

    my %matching_sequences = %{$self->matching_sequences};
    my %combined_sequences = (%matching_sequences);
    
    if(defined($self->non_matching_sequences) && %{$self->non_matching_sequences})
    {
      my %non_matching_sequences = %{$self->non_matching_sequences};
      %combined_sequences = (%matching_sequences, %non_matching_sequences);
    }
    my $concat_sequence = $self->_sort_and_join_sequences(\%combined_sequences);
    
    $self->concat_sequence($concat_sequence);
  }
  
  if(defined($self->non_matching_sequences) && %{$self->non_matching_sequences})
  {
   # create 1 FASTA file for each unknown allele with a close match to another allele
    for my $sequence_name (keys %{$self->non_matching_sequences})
    {
      next if(length($self->non_matching_sequences->{$sequence_name}) < 2);
      next if($self->_does_sequence_contain_all_unknowns($self->non_matching_sequences->{$sequence_name}));
      my $non_matching_output_filename = join('/',($self->output_directory, $self->_fasta_filename.'.unknown_allele.'.$sequence_name.'.fa'));
      my $out = Bio::SeqIO->new(-file => "+>$non_matching_output_filename" , '-format' => 'Fasta');
      $out->write_seq(Bio::PrimarySeq->new(-seq => $self->non_matching_sequences->{$sequence_name}, -id  => $sequence_name));
    }
  }
  1;
}

sub _does_sequence_contain_all_unknowns
{
  my($self, $sequence) = @_;
  return 1 if($sequence =~ m/^N+$/);
  return 0;
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;
