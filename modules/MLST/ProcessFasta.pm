=head1 NAME

ProcessFasta - Take in a fasta file, lookup the MLST database and create relevant files.

=head1 SYNOPSIS

use MLST::ProcessFasta;
MLST::ProcessFasta->new(
  'species'           => 'E.coli',
  'base_directory'    => '/path/to/dir',
  'fasta_file'        => 'myfasta.fa',
  'makeblastdb_exec'  => 'makeblastdb',
  'blastn_exec'       => 'blastn',
  'output_directory'  => '/path/to/output',
  'output_fasta_files'=> 1,
);

=cut

package MLST::ProcessFasta;
use Moose;
use MLST::SearchForFiles;
use MLST::CompareAlleles;
use MLST::SequenceType;
use MLST::OutputFasta;
use MLST::Spreadsheet::Row;

has 'species'             => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'base_directory'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'fasta_file'          => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'makeblastdb_exec'    => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'blastn_exec'         => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_directory'    => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_fasta_files'  => ( is => 'ro', isa => 'Boolean',  default  => 0 ); 

has '_search_results'     => ( is => 'ro', isa => 'MLST::SearchForFiles',  lazy => 1, builder => '_build__search_results' ); 
has '_compare_alleles'    => ( is => 'ro', isa => 'MLST::CompareAlleles',  lazy => 1, builder => '_build__compare_alleles' ); 
has '_sequence_type_obj'  => ( is => 'ro', isa => 'MLST::SequenceType',    lazy => 1, builder => '_build__sequence_type_obj' ); 
has '_spreadsheet_row_obj' => ( is => 'ro', isa => 'MLST::Spreadsheet::Row',    lazy => 1, builder => '_build__spreadsheet_row_obj' ); 

sub _build__search_results
{
  my($self) = @_;
  MLST::SearchForFiles->new(
    species_name   => $self->species,
    base_directory => $self->base_directory
  );
}

sub _build__compare_alleles
{
  my($self) = @_;
  my $compare_alleles = MLST::CompareAlleles->new(
    sequence_filename => $self->fasta_file,
    allele_filenames  => $self->_search_results->allele_filenames(),
    makeblastdb_exec  => $self->makeblastdb_exec,
    blastn_exec       => $self->blastn_exec
  );
  
  if(defined($self->output_fasta_files))
  {
    MLST::OutputFasta->new(
      matching_sequences     => $compare_alleles->matching_sequences,
      non_matching_sequences => $compare_alleles->non_matching_sequences,
      output_directory       => $self->output_directory,
      input_fasta_file       => $self->fasta_file
    )->create_files();
  }
  return $compare_alleles;
}

sub _build__sequence_type_obj
{
  my($self) = @_;
  my $sequence_type_obj = MLST::SequenceType->new(
    profiles_filename => $self->_search_results->profiles_filename(),
    sequence_names    => $self->_compare_alleles->found_sequence_names
  );
}

sub _build__spreadsheet_row_obj
{
  my($self) = @_;
  MLST::Spreadsheet::Row->new(
    sequence_type_obj => $self->_sequence_type_obj, 
    compare_alleles   => $self->_compare_alleles
  );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
