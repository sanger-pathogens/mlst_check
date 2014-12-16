package Bio::MLST::Spreadsheet::Row;
# ABSTRACT: Create a row representation of the ST results for a single fasta file.

=head1 SYNOPSIS

Create a row representation of the ST results for a single fasta file.

   use Bio::MLST::Spreadsheet::Row;
   my $spreadsheet_row_obj = Bio::MLST::Spreadsheet::Row->new(
     sequence_type_obj => $sequence_type_obj, 
     compare_alleles   => $compare_alleles
   );
   
   $spreadsheet_row_obj->allele_numbers_row;
   $spreadsheet_row_obj->genomic_row;

=method allele_numbers_row

Returns the spreadsheet row of results containing the allele numbers of the matching sequences.

=method genomic_row

Returns the spreadsheet row of results containing the genomic sequences of the matches.

=head1 SEE ALSO

=for :list
* L<Bio::MLST::Spreadsheet::File>

=cut

use Moose;

has 'sequence_type_obj'  => ( is => 'ro', isa => 'Bio::MLST::SequenceType',     required => 1 ); 
has 'compare_alleles'    => ( is => 'ro', isa => 'Bio::MLST::CompareAlleles',   required => 1 ); 
has 'show_contamination_instead_of_alt_matches' => ( is => 'ro', isa => 'Bool',   default => 1 ); 
                        
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

  my $contamination_cell;
  if($self->show_contamination_instead_of_alt_matches == 1)
  {
    $contamination_cell = ($self->compare_alleles->contamination ? $self->compare_alleles->contamination_alleles : '');
  }
  else
  {
    $contamination_cell = (defined($self->compare_alleles->contamination_sequence_names)) ? join(',',@{$self->compare_alleles->contamination_sequence_names}) : '';
  }
  
  
  my @common_cells = (
    $self->compare_alleles->sequence_filename_root,
    $self->sequence_type_obj->sequence_type_or_nearest,
    $new_st_cell,
    $contamination_cell,
  );
  return \@common_cells;
}

sub _build__allele_order {
  my $self = shift;
  my $profile_path = $self->compare_alleles->profiles_filename;

  open( my $profile_fh, '<', $profile_path );
  my $line = <$profile_fh>;
  chomp $line;
  my @alleles = split(/\s+/, $line);
  @alleles = grep { $_ ne 'ST' } @alleles;
  @alleles = grep { $_ ne 'clonal_complex' } @alleles;

  return \@alleles;
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
  
  my @allele_headers;
  for my $sequence_name (@{$self->_allele_order})
  {
    $sequence_name =~ s!_!-!g;
    $sequence_name =~ s!-+!-!g;
    #my @sequence_name_details = split(/[-_]+/,$sequence_name);
    #push(@allele_headers,$sequence_name_details[0]);
    push( @allele_headers, $sequence_name );
  }
  
  my $contamination_cell ;
  if($self->show_contamination_instead_of_alt_matches == 1)
  {
    $contamination_cell =   'Contamination';
  }
  else
  {
    $contamination_cell = 'Alternatives';
  }
  
  my @header_cells = (('Isolate', 'ST','New ST', $contamination_cell ), @allele_headers);
  return \@header_cells;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
