=head1 NAME
Bio::MLST::Spreadsheet::Row
=head1 SYNOPSIS
Create a row representation of the ST results for a single fasta file.

=head1 DESCRIPTION

use Bio::MLST::Spreadsheet::Row;
my $spreadsheet_row_obj = Bio::MLST::Spreadsheet::Row->new(
  sequence_type_obj => $sequence_type_obj, 
  compare_alleles   => $compare_alleles
);

$spreadsheet_row_obj->allele_numbers_row;
$spreadsheet_row_obj->genomic_row;
=head1 CONTACT
path-help@sanger.ac.uk
=cut

package Bio::MLST::Spreadsheet::Row;
use Moose;

has 'sequence_type_obj'  => ( is => 'ro', isa => 'Bio::MLST::SequenceType',     required => 1 ); 
has 'compare_alleles'    => ( is => 'ro', isa => 'Bio::MLST::CompareAlleles',   required => 1 ); 
                        
has 'allele_numbers_row' => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_allele_numbers_row'); 
has 'genomic_row'        => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_genomic_row'); 
has 'header_row'         => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_header_row'); 
has '_common_cells'      => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__common_cells'); 
has '_allele_order'      => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__allele_order'); 

sub _build__common_cells
{
  my($self) = @_;
  
  #cause the variable to be built.
  $self->sequence_type_obj->sequence_type;
  my $new_st_cell = '';
  if($self->compare_alleles->new_st )
  {
     $new_st_cell = "Unknown";
  }
  elsif($self->sequence_type_obj->nearest_sequence_type)
  {
     $new_st_cell = "Novel ST";
  }

  
  my @common_cells = (
    $self->compare_alleles->sequence_filename_root,
    $self->sequence_type_obj->sequence_type_or_nearest,
    $new_st_cell,
    ($self->compare_alleles->contamination ? "Contamination" : ''),
  );
  return \@common_cells;
}

sub _build__allele_order
{
  my($self) = @_;
  my @not_found_sequences  = @{$self->compare_alleles->found_non_matching_sequence_names};
  my @found_sequences = keys(%{$self->sequence_type_obj->allele_to_number});
  my @combined_names  = sort((@not_found_sequences , @found_sequences));
  return \@combined_names;
}

sub _build_allele_numbers_row
{
  my($self) = @_;
  my @common_cells = @{$self->_common_cells};
  my @allele_cells;
  
  for my $allele_name (@{$self->_allele_order})
  {
    if(defined($self->sequence_type_obj->allele_to_number->{$allele_name}))
    {
      push(@allele_cells,$self->sequence_type_obj->allele_to_number->{$allele_name});
    }
    else
    {
       push(@allele_cells,'U');
    }
  }
  my @complete_row = (@common_cells,@allele_cells);
  return \@complete_row;
}

sub _build_genomic_row
{
  my($self) = @_;
  my @common_cells = @{$self->_common_cells};
  my @allele_cells;
  
  for my $allele_name (@{$self->_allele_order})
  {
    if(defined($self->sequence_type_obj->allele_to_number->{$allele_name}))
    {
       my $original_allele_name = $allele_name.'-'.$self->sequence_type_obj->allele_to_number->{$allele_name};
       if(defined($self->compare_alleles->matching_sequences->{$original_allele_name}))
       {
         push(@allele_cells,$self->compare_alleles->matching_sequences->{$original_allele_name});
       }
       elsif(defined($self->compare_alleles->non_matching_sequences->{$original_allele_name}))
       {
         push(@allele_cells,$self->compare_alleles->non_matching_sequences->{$original_allele_name});
       }
       else
       {
          push(@allele_cells,'U');
       }
    }
    else
    {
       push(@allele_cells,'U');
    }
    
  }
  my @complete_row = (@common_cells,@allele_cells);
  return \@complete_row;
}

sub _build_header_row
{
  my($self) = @_;
  my @header_cells = (('Isolate', 'ST','New ST', 'Contamination'), @{$self->_allele_order});
  return \@header_cells;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
