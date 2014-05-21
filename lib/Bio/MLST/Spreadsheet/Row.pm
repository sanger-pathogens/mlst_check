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
use Digest::MD5 qw(md5_hex);

has 'md5_opt'            => ( is => 'ro', isa => 'Bool',                        required => 1 ); 
has 'sequence_type_obj'  => ( is => 'ro', isa => 'Bio::MLST::SequenceType',     required => 1 ); 
has 'compare_alleles'    => ( is => 'ro', isa => 'Bio::MLST::CompareAlleles',   required => 1 ); 
has 'show_contamination_instead_of_alt_matches' => ( is => 'ro', isa => 'Bool',  default => 1 ); 
                        
has 'allele_numbers_row' => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_allele_numbers_row'); 
has 'genomic_row'        => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_genomic_row'); 
has 'header_row'         => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_header_row'); 
has '_common_cells'      => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__common_cells'); 
has '_allele_order'      => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__allele_order');
has 'non_matching_sequences_with_modified_allele_names' => ( is => 'rw', isa => 'HashRef', default => sub {{}});

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
    $contamination_cell = ($self->compare_alleles->contamination ? "Contamination" : '');
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
  # Building new non matching sequence object with the modified allele names (as in SequenceType.pm -,_ removed)
  my $seq;
  foreach my $allele_name (keys %{$self->compare_alleles->non_matching_sequences}) {
    # Assiging the value to a variable before changing the actual key below
    $seq = $self->compare_alleles->non_matching_sequences->{$allele_name};
    $allele_name =~ s/_/-/g;
    $allele_name =~ s/-+/-/g;
    $self->non_matching_sequences_with_modified_allele_names->{$allele_name} = $seq;
  }

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
      # If selected md5 output view, then call _handle_unknown_allele_row()
      push(@allele_cells, ($self->md5_opt)?_handle_unknown_allele_row($self->non_matching_sequences_with_modified_allele_names->{$allele_name}) : 'U');
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
          # If selected md5 output view, then call _handle_unknown_genomic_row()
          push(@allele_cells, ($self->md5_opt)?_handle_unknown_genomic_row($self->non_matching_sequences_with_modified_allele_names->{$allele_name}) : 'U');
       }
    }
    else
    {
      # If selected md5 output view, then call _handle_unknown_genomic_row()
      push(@allele_cells, ($self->md5_opt)?_handle_unknown_genomic_row($self->non_matching_sequences_with_modified_allele_names->{$allele_name}) : 'U');
    }
  }
  my @complete_row = (@common_cells,@allele_cells);
  return \@complete_row;
}

sub _handle_unknown_allele_row {
  # Create an md5sum if there are non-mathcing sequences
  my $seq = shift || '';
  my $str = $seq;
  my $digest;
  if($str ne "") {
    $str =~ tr///cs;
    if($str ne "N") {
      $digest = md5_hex($seq);
      return $digest;
    }
    elsif($str eq "N") {
      return "N"; # all N's
    }
    else {
      return 'U';
    }
  }
  else {
    return 'U'; # sequence null
  }
}

sub _handle_unknown_genomic_row {
  # Print the actual sequence for non-matching sequences
  my $seq = shift || '';
  my $str = $seq;
  #my $digest;
  if($str ne "") {
    $str =~ tr///cs;
    if($str ne "N") {
      #$digest = md5_hex($str);
      return $seq;
    }
    elsif($str eq "N") {
      return "N"; # all N's
    }
    else {
      return 'U';
    }
  }
  else {
    return 'U'; # sequence null
  }

}
sub _build_header_row
{
  my($self) = @_;
  
  my @allele_headers;
  for my $sequence_name (@{$self->_allele_order})
  {
    $sequence_name =~ s!_!-!g;
    $sequence_name =~ s!-+!-!g;
    my @sequence_name_details = split(/[-_]+/,$sequence_name);
    push(@allele_headers,$sequence_name_details[0]);
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
