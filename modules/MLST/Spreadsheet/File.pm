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

has 'spreadsheet_rows'      => ( is => 'ro', isa => 'ArrayRef[MLST::Spreadsheet::Row]', required => 1 ); 
has 'output_directory'      => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'spreadsheet_basename'  => ( is => 'ro', isa => 'Str', required => 1 ); 

has '_header'           => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__header' ); 

sub create
{
  my($self) = @_;
  my $base_spreadsheet_name = join('/',($self->output_directory, $self->spreadsheet_basename));
  
  open(my $allele_fh,'+>', $base_spreadsheet_name.".allele.csv");
  open(my $genomic_fh,'+>', $base_spreadsheet_name.".genomic.csv");
  
  my $allele_csv = Text::CSV->new();
  my $genomic_csv = Text::CSV->new();
  
  $allele_csv->print ($allele_fh, $_) for @{$self->_header};
  $genomic_csv->print ($genomic_fh, $_) for @{$self->_header};
  
  for my $row (@{$self->spreadsheet_rows})
  {
    $allele_csv->print ($allele_fh, $_) for @{$row->allele_numbers_row};
    $genomic_csv->print ($genomic_fh, $_) for @{$row->genomic_row};
  }
  close($allele_fh);
  close($genomic_fh);
}

sub _build__header
{
  my($self) = @_;
  my @rows = @{$self->spreadsheet_rows};
  return $rows[0]->header_row;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
