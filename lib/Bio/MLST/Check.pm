=head1 NAME

Bio::MLST::Check

=head1 SYNOPSIS

High throughput multilocus sequence typing (MLST) checking

=head1 DESCRIPTION

This application is for taking Multilocus sequence typing (MLST) sources from multiple locations and consolidating them in one place so that they can be easily used (and kept up to date).
Then you can provide FASTA files and get out sequence types for a given MLST database.
Two spreadsheets are outputted, one contains the allele number for each locus, and the ST (or nearest ST), the other contains the genomic sequence for each allele.  
If more than 1 allele gives 100% identity for a locus, the contaminated flag is set.
Optionally you can output a concatenated sequence in FASTA format, which you can then use with tree building programs.
New, unseen alleles are saved in FASTA format, with 1 per file, for submission to back to MLST databases.

It requires NCBI Blast+ to be installed and for blastn and makeblastdb to be in your PATH.

Example usage
-------------

# Add this environment variable to your ~/.bashrc file - do this once
export MLST_DATABASES=/path/to/where_you_want_to_store_the_databases

# Download the latest copy of the databases (run it once per month)
download_mlst_databases

# Find the sequence types for all fasta files in your current directory
get_sequence_type -s "Clostridium difficile" *.fa



use Bio::MLST::Check;
Bio::MLST::Check->new(
  'species'           => 'E.coli',
  'base_directory'    => '/path/to/dir',
  'raw_input_fasta_files'  => ['myfasta.fa'],
  'makeblastdb_exec'  => 'makeblastdb',
  'blastn_exec'       => 'blastn',
  'output_directory'  => '/path/to/output',
  'output_fasta_files'=> 1,
);

=head1 CONTACT

path-help@sanger.ac.uk

=cut
# ABSTRACT: Multilocus sequence typing checking

package Bio::MLST::Check;
use Moose;
use Parallel::ForkManager;
use Bio::MLST::ProcessFasta;
use Bio::MLST::Spreadsheet::File;
use Bio::MLST::NormaliseFasta;
use Bio::AlignIO;
use Bio::SimpleAlign;
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
has 'output_phylip_files'   => ( is => 'ro', isa => 'Bool',     default  => 0 ); 

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
    
    my $output_fasta_obj = Bio::MLST::NormaliseFasta->new(
      fasta_filename     => $fastafile,
      working_directory  => $self->_working_directory->dirname()
    );
    
    my $fasta_sequence_type_results = Bio::MLST::ProcessFasta->new(
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
  
  my $spreadsheet = Bio::MLST::Spreadsheet::File->new(
    header                          => pop(@{$self->_spreadsheet_header}),
    spreadsheet_allele_numbers_rows => $self->_spreadsheet_allele_numbers_rows,
    spreadsheet_genomic_rows        => $self->_spreadsheet_genomic_rows,
    output_directory                => $self->output_directory,
    spreadsheet_basename            => $self->spreadsheet_basename
  );
  $spreadsheet->create();
  
  if($self->output_fasta_files)
  {
    $self->_create_alignment('Fasta','fa');
  }
  
  if($self->output_phylip_files)
  {
    $self->_create_alignment('phylip','phylip');
  }
  1;
}

sub _create_alignment
{
  my($self, $format, $extension) = @_;
  
  my $output_filename = join('/',($self->output_directory,'concatenated_alleles.'.$extension));
  my $out = Bio::AlignIO->new(-file => "+>$output_filename" , '-format' => $format);
  my $aln = Bio::SimpleAlign->new();
  for(my $i = 0;  $i < @{$self->_concat_names}; $i++)
  {
    next unless(defined( $self->_concat_sequences->[$i]));
    $aln->add_seq(Bio::LocatableSeq->new(
        -seq   => $self->_concat_sequences->[$i], 
        -id    => $self->_concat_names->[$i], 
        -start => 1, 
        -end   => length($self->_concat_sequences->[$i]) 
      ));
  }
  $out->write_aln($aln);
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
