package Bio::MLST::NormaliseFasta;
# ABSTRACT: Take in a Fasta file, check for invalid characters and build a corrected file if needed. 

=head1 SYNOPSIS

Take in a Fasta file, check for invalid characters and build a corrected file if needed. 
This is needed for NCBI makeblastdb which doesnt like the pipe character in the sequence name.

   use Bio::MLST::NormaliseFasta;
   
   my $output_fasta = Bio::MLST::NormaliseFasta->new(
     fasta_filename     => 'Filename.fasta'
   
   );
   $output_fasta->processed_fasta_filename();

=method processed_fasta_filename

Output a temporary fasta file thats been cleaned up.

=cut

use Moose;
use Bio::SeqIO;
use File::Basename;
use Bio::MLST::Types;

has 'fasta_filename'      => ( is => 'ro', isa => 'Bio::MLST::File',  required => 1 ); 
has 'working_directory'   => ( is => 'ro', isa => 'Str',         required => 1 ); 

has '_normalised_fasta_filename' => ( is => 'ro', isa => 'Str',  lazy => 1, builder => '_build__normalised_fasta_filename' ); 

sub _build__normalised_fasta_filename
{
  my($self) = @_;
  my $fasta_obj =  Bio::SeqIO->new( -file => $self->fasta_filename , -format => 'Fasta');
  
  while(my $seq = $fasta_obj->next_seq())
  {
    if($seq->id =~ m/\|/ )
    {
      return $self->_rename_sequences();
    }
  }
  
  return $self->fasta_filename;
}

sub _rename_sequences
{
  my($self) = @_;
  my $in_fasta_obj =  Bio::SeqIO->new( -file => $self->fasta_filename , -format => 'Fasta');
  my($filename, $directories, $suffix) = fileparse($self->fasta_filename);
  my $output_filename = $self->working_directory.'/'.$filename.$suffix ;
  my $out_fasta_obj = Bio::SeqIO->new(-file => "+>".$output_filename , -format => 'Fasta');
  
  my $counter = 1;
  while(my $seq = $in_fasta_obj->next_seq())
  {
    $seq->id($counter."");
    $out_fasta_obj->write_seq($seq);
    $counter++;
  }
  return $output_filename;
}

sub processed_fasta_filename
{
  my($self) = @_;
  return $self->_normalised_fasta_filename;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

