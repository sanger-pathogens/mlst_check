=head1 NAME

Database - Take in a fasta file and create a tempory blast database

=head1 SYNOPSIS

use MLST::Blast::Database;

my $blast_database= MLST::Blast::Database->new(
  fasta_file => 'contigs.fa',
  exec => 'makeblastdb'
);

$blast_database->location();

=cut

package MLST::Blast::Database;
use Moose;
use File::Temp;

# input variables
has 'fasta_file'         => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'exec'               => ( is => 'ro', isa => 'Str', required => 1 ); 

# Generated
has '_working_directory' => ( is => 'ro', isa => 'File::Temp::Dir', default => sub { File::Temp->newdir(CLEANUP => 1); });
has 'location'           => ( is => 'ro', isa => 'Str', lazy => 1,  builder => '_build_location' ); 

sub _build_location
{
  my($self) = @_;
  my $output_database = join('/',($self->_working_directory->dirname(),'output_contigs'));
  my $makeblastdb_cmd  = join(" ",($self->exec, '-in', $self->fasta_file,  '-dbtype nucl', '-parse_seqids', '-out', $output_database));
  # FIXME: run this command in a more sensible fashion
  `$makeblastdb_cmd`;
  return $output_database;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

#/software/pubseq/bin/ncbi-blast-2.2.25+/bin/makeblastdb -in contigs.fa  -dbtype nucl -parse_seqids -out output_contigs 
#/software/pubseq/bin/ncbi-blast-2.2.25+/bin/blastn -task blastn -query Escherichia_coli_1/alleles/adk.tfa -db output_contigs -outfmt 6  -word_size 500
#
#create tmp directory
#get the length of the mlst queries
#make a database from the input fasta file
#parse blastn output
#extract top hit
#- extract the genomic region from the fasta file
#cleanup

