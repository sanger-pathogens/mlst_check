=head1 NAME

Bio::MLST::Blast::Database

=head1 SYNOPSIS
Take in a fasta file and create a tempory blast database

=head1 DESCRIPTION

use Bio::MLST::Blast::Database;

my $blast_database= Bio::MLST::Blast::Database->new(
  fasta_file => 'contigs.fa',
  exec => 'makeblastdb'
);

$blast_database->location();
=head1 CONTACT
path-help@sanger.ac.uk
=cut

package Bio::MLST::Blast::Database;
use Moose;
use File::Temp;
use Bio::MLST::Types;
use Cwd;

# input variables
has 'fasta_file'         => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'exec'               => ( is => 'ro', isa => 'Bio::MLST::Executable', default  => 'makeblastdb' ); 

# Generated
has '_working_directory' => ( is => 'ro', isa => 'File::Temp::Dir', default => sub { File::Temp->newdir(DIR => getcwd, CLEANUP => 1); });
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
