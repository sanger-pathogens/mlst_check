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
use MLST::NormaliseFasta;
use File::Temp;
use Cwd;

has 'species'               => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'base_directory'        => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'raw_input_fasta_files' => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 
has 'makeblastdb_exec'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'blastn_exec'           => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_directory'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_fasta_files'    => ( is => 'ro', isa => 'Bool',     default  => 0 ); 
has 'spreadsheet_basename'  => ( is => 'ro', isa => 'Str',      default  => 'mlst_results' ); 

has 'parallel_processes'    => ( is => 'ro', isa => 'Int',      default  => 1 ); 

has '_spreadsheet_header'              => ( is => 'rw', isa => 'ArrayRef', default => sub {[]} ); 
has '_spreadsheet_allele_numbers_rows' => ( is => 'rw', isa => 'ArrayRef', default => sub {[]} ); 
has '_spreadsheet_genomic_rows'        => ( is => 'rw', isa => 'ArrayRef', default => sub {[]} ); 
has '_input_fasta_files'    => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__input_fasta_files'); 

has '_concat_names'      => ( is => 'rw', isa => 'ArrayRef', default => sub {[]} ); 
has '_concat_sequences' => ( is => 'rw', isa => 'ArrayRef', default => sub {[]} ); 
has '_working_directory' => ( is => 'ro', isa => 'File::Temp::Dir', default => sub { File::Temp->newdir(DIR => getcwd, CLEANUP => 1); });

sub _generate_spreadsheet_rows
{
  my($self) = @_;

  my $pm = new Parallel::ForkManager($self->parallel_processes); 
  $pm -> run_on_finish (
    sub {
      my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;
      # retrieve data structure from child
      if (defined($data_structure_reference)) {  # children are not forced to send anything
        push(@{$self->_spreadsheet_header}, $data_structure_reference->[0]);
        push(@{$self->_spreadsheet_allele_numbers_rows}, $data_structure_reference->[1]);
        push(@{$self->_spreadsheet_genomic_rows}, $data_structure_reference->[2]);
        
        push(@{$self->_concat_names}, $data_structure_reference->[3]);
        push(@{$self->_concat_sequences}, $data_structure_reference->[4]);

      } else {  # problems occuring during storage or retrieval will throw a warning
        print qq|No message received from child process $pid!\n|;
      }
    }
  );
  
  for my $fastafile (@{$self->_input_fasta_files})
  {
    $pm->start and next; # do the fork
    
    my $output_fasta_obj = MLST::NormaliseFasta->new(
      fasta_filename     => $fastafile,
      working_directory  => $self->_working_directory->dirname()
    );
    
    my $fasta_sequence_type_results = MLST::ProcessFasta->new(
      species            => $self->species,
      base_directory     => $self->base_directory,
      fasta_file         => $output_fasta_obj->processed_fasta_filename(),
      makeblastdb_exec   => $self->makeblastdb_exec,
      blastn_exec        => $self->blastn_exec,
      output_directory   => $self->output_directory,
      output_fasta_files => $self->output_fasta_files
    );
    my @result_rows;
    push(@result_rows, ($fasta_sequence_type_results->_spreadsheet_row_obj->header_row,
                        $fasta_sequence_type_results->_spreadsheet_row_obj->allele_numbers_row,
                        $fasta_sequence_type_results->_spreadsheet_row_obj->genomic_row,
                        $fasta_sequence_type_results->concat_name,
                        $fasta_sequence_type_results->concat_sequence));
     
    $pm->finish(0,\@result_rows); # do the exit in the child process
  }
  $pm->wait_all_children;
  1;
}

sub _build__input_fasta_files
{
  my($self) = @_;
  return $self->raw_input_fasta_files;
}

sub create_result_files
{
  my($self) = @_;
  $self->_generate_spreadsheet_rows;
  
  my $spreadsheet = MLST::Spreadsheet::File->new(
    header                          => pop(@{$self->_spreadsheet_header}),
    spreadsheet_allele_numbers_rows => $self->_spreadsheet_allele_numbers_rows,
    spreadsheet_genomic_rows        => $self->_spreadsheet_genomic_rows,
    output_directory                => $self->output_directory,
    spreadsheet_basename            => $self->spreadsheet_basename
  );
  $spreadsheet->create();
  
  if($self->output_fasta_files)
  {
    my $output_filename = join('/',($self->output_directory,'concatenated_alleles.fa'));
    my $out = Bio::SeqIO->new(-file => "+>$output_filename" , '-format' => 'Fasta');
    for(my $i = 0;  $i < @{$self->_concat_names}; $i++)
    {
      next unless(defined( $self->_concat_sequences->[$i]));
      $out->write_seq(Bio::PrimarySeq->new(-seq => $self->_concat_sequences->[$i], -id  => $self->_concat_names->[$i]));
    }
  }
  1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
