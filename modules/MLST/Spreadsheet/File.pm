=head1 NAME

Spreadsheet::File - Create a row representation of the ST results for a single fasta file.

=head1 SYNOPSIS

use MLST::Spreadsheet::File;
my $spreadsheet = MLST::Spreadsheet::File->new(
  spreadsheet_rows => [],
  output_directory => '/path/to/outputdir',
  spreadsheet_basename => 'abc'
);

$spreadsheet->create();

=cut

package MLST::Spreadsheet::File;
use Moose;
use Text::CSV;
use MLST::Spreadsheet::Row;

has 'spreadsheet_allele_numbers_rows'      => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 
has 'spreadsheet_genomic_rows'             => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 
has 'output_directory'      => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'spreadsheet_basename'  => ( is => 'ro', isa => 'Str', required => 1 ); 

has 'header'           => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 

sub create
{
  my($self) = @_;
  my $base_spreadsheet_name = join('/',($self->output_directory, $self->spreadsheet_basename));
  
  open(my $allele_fh,'+>', $base_spreadsheet_name.".allele.csv");
  open(my $genomic_fh,'+>', $base_spreadsheet_name.".genomic.csv");
  
  my $allele_csv = Text::CSV->new();
  my $genomic_csv = Text::CSV->new();
  $allele_csv->eol ("\r\n");
  $genomic_csv->eol ("\r\n");
  
  $allele_csv->print ($allele_fh, $_) for $self->header;
  $genomic_csv->print ($genomic_fh, $_) for $self->header;
  
  for my $row (@{$self->spreadsheet_allele_numbers_rows})
  {
    $allele_csv->print ($allele_fh, $_) for $row;
  }
  for my $row (@{$self->spreadsheet_genomic_rows})
  {
    $genomic_csv->print ($genomic_fh, $_) for $row;
  }
  close($allele_fh);
  close($genomic_fh);
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
