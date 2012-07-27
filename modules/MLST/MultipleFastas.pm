=head1 NAME

MultipleFastas - Take in a list of fasta files, lookup the MLST database and create relevant files.

=head1 SYNOPSIS

use MLST::MultipleFastas;
MLST::MultipleFastas->new(
  'species'           => 'E.coli',
  'base_directory'    => '/path/to/dir',
  'raw_input_fasta_files'  => ['myfasta.fa'],
  'makeblastdb_exec'  => 'makeblastdb',
  'blastn_exec'       => 'blastn',
  'output_directory'  => '/path/to/output',
  'output_fasta_files'=> 1,
);

=cut

package MLST::MultipleFastas;
use Moose;
use Parallel::ForkManager;
use MLST::ProcessFasta;
use MLST::Spreadsheet::File;

has 'species'               => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'base_directory'        => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'raw_input_fasta_files' => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 
has 'makeblastdb_exec'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'blastn_exec'           => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_directory'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_fasta_files'    => ( is => 'ro', isa => 'Bool',     default  => 0 ); 
has 'spreadsheet_basename'  => ( is => 'ro', isa => 'Str',      default  => 'mlst_results' ); 

has 'parallel_processes'    => ( is => 'ro', isa => 'Int',      default  => 1 ); 

has '_spreadsheet_rows'     => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__spreadsheet_rows' ); 
has '_input_fasta_files'    => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__input_fasta_files'); 

sub _build__spreadsheet_rows
{
  my($self) = @_;
  my @spreadsheet_rows;
  my $pm = new Parallel::ForkManager($self->parallel_processes); 
  for my $fastafile (@{$self->_input_fasta_files})
  {
    $pm->start and next; # do the fork
    my $fasta_sequence_type_results = MLST::ProcessFasta->new(
      species            => $self->species,
      base_directory     => $self->base_directory,
      fasta_file         => $self->fastafile,
      makeblastdb_exec   => $self->makeblastdb_exec,
      blastn_exec        => $self->blastn_exec,
      output_directory   => $self->output_directory,
      output_fasta_files => $self->fasta_files
    );
    push(@spreadsheet_rows, $fasta_sequence_type_results->_spreadsheet_row_obj);
    $pm->finish; # do the exit in the child process
  }
  $pm->wait_all_children;
  return \@spreadsheet_rows;
}

sub _build__input_fasta_files
{
  my($self) = @_;
  # TODO: Validate and Reformat the fasta files if theres a pipe character

  # Validate
  for my $fastafile (@{$self->raw_input_fasta_files})
  {
    if(!(-e $fastafile ))
    {
      die "Input file doesnt exist: $fastafile\n";
    }
  }
  
  return $self->raw_input_fasta_files;
}

sub create_result_files
{
  my($self) = @_;
  my $spreadsheet = MLST::Spreadsheet::File->new(
    spreadsheet_rows => $self->spreadsheet_rows,
    output_directory => $self->output_directory,
    spreadsheet_basename => $self->spreadsheet_basename
  );
  $spreadsheet->create();
  1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
