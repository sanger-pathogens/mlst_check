package Bio::MLST::SequenceType;
# ABSTRACT: Take in a list of matched alleles and look up the sequence type from the profile.

=head1 SYNOPSIS

Take in a list of matched alleles and look up the sequence type from the profile.

  use Bio::MLST::SequenceType;
  my $st = Bio::MLST::SequenceType->new(
    profiles_filename  => 't/data/Escherichia_coli_1/profiles/escherichia_coli.txt',
    matching_names     => ['adk-2','purA-3','recA-1'],
    non_matching_names => []
  );
  $st->sequence_type();

=method allele_to_number

Maps the allele name to the corresponding locus sequence number.

=method sequence_type

Returns the sequence type (an integer).

=method nearest_sequence_type

Returns the nearest matching sequence type if there is no exact match, randomly chosen if there is more than 1 with equal identity.

=cut

use Data::Dumper;
use Text::CSV;
use List::Util qw(min reduce);

use Moose;
use Bio::MLST::Types;

has 'profiles_filename'     => ( is => 'ro', isa => 'Bio::MLST::File',        required => 1 ); 
has 'matching_names'        => ( is => 'ro', isa => 'ArrayRef',   required => 1 );
has 'non_matching_names'        => ( is => 'ro', isa => 'ArrayRef',   required => 1 );

has 'allele_to_number'      => ( is => 'ro', isa => 'HashRef',    lazy => 1, builder => '_build_allele_to_number' ); 
has '_profiles'             => ( is => 'ro', isa => 'ArrayRef',   lazy => 1, builder => '_build__profiles' );
has 'sequence_type'         => ( is => 'ro', isa => 'Maybe[Str]', lazy => 1, builder => '_build_sequence_type' );

has 'nearest_sequence_type' => ( is => 'rw', isa => 'Maybe[Str]');
has 'report_lowest_st'  => ( is => 'ro', isa => 'Bool', default => 0 );

sub sequence_type_or_nearest
{
  my($self) = @_;
  return $self->sequence_type if(defined($self->sequence_type));
  # If there isn't a perfect match, add a tilde to the sequence type
  return $self->nearest_sequence_type."~" if(defined($self->nearest_sequence_type));
  return $self->nearest_sequence_type;
}

sub _build__profiles
{
  my($self) = @_;
  open(my $fh, $self->profiles_filename) or die "Couldnt open profile: ".$self->profiles_filename."\n";
  my $csv_in = Text::CSV->new({sep_char=>"\t"});
  my $profile = $csv_in->getline_all($fh);
  
  return $profile;
}

sub _build_allele_to_number
{
  my($self) = @_;
  my %allele_to_number;

  for my $sequence_name (@{$self->non_matching_names})
  {
    my @sequence_name_details = split(/[-_]/,$sequence_name);
    my $num = pop @sequence_name_details;
    my $name = join( "-", @sequence_name_details );
    $allele_to_number{$name} = $num;
  }

  for my $sequence_name (@{$self->matching_names})
  {
    my @sequence_name_details = split(/[-_]/,$sequence_name);
    my $num = pop @sequence_name_details;
    my $name = join( "-", @sequence_name_details );
    $allele_to_number{$name} = $num;
  }

  #print "ALLELE TO NUMBER: ";
  #print Dumper \%allele_to_number;
  
  return \%allele_to_number;
}

sub _allele_numbers_similar
{
  my($self, $number_a, $number_b) = @_;
  if ($number_a eq $number_b) {
    return 1;
  } elsif ("$number_a~" eq $number_b) {
    return 1;
  } elsif ("$number_b~" eq $number_a) {
    return 1;
  } else {
    return 0;
  }
}

sub _build_sequence_type
{
  my($self) = @_;
  
  my @header_row = @{$self->_profiles->[0]};
  
  for(my $i=0; $i< @header_row; $i++)
  {
    next if($header_row[$i] eq "clonal_complex");
    next if($header_row[$i] eq "mlst_clade");
    $header_row[$i] =~ s!_!!g;
    $header_row[$i] =~ s!-!!g;
  }
  
  my $num_loci = 0;
  my %sequence_type_match_freq;
  my %sequence_type_part_match_freq;
  
  for(my $row = 1; $row < @{$self->_profiles}; $row++)
  {
    my @current_row = @{$self->_profiles->[$row]};
    for(my $col = 0; $col< @current_row; $col++)
    {
      next if($header_row[$col] eq "ST" || $header_row[$col] eq "clonal_complex" || $header_row[$col] eq "mlst_clade");
      $num_loci++ if($row == 1);

      my $allele_number = $self->allele_to_number->{$header_row[$col]};
      next if(!defined($allele_number) );
      if ($allele_number eq $current_row[$col]) {
        $sequence_type_match_freq{$current_row[0]}++;
      } elsif ($self->_allele_numbers_similar($allele_number, $current_row[$col])) {
        $sequence_type_part_match_freq{$current_row[0]}++;
      }
    }
  }
  
  return $self->_get_sequence_type_or_set_nearest_match(\%sequence_type_match_freq,
                                                        \%sequence_type_part_match_freq,
                                                        $num_loci);	
}

sub _get_sequence_type_or_set_nearest_match
{
  my($self,$st_match_f, $st_part_match_f, $num_loci) = @_;
  my %st_match_freq = %{$st_match_f};

  # Combine the frequencies of the perfect matches (%st_match_freq) and the
  # partial matches ($st_part_match_f)
  my %st_nearest_match_freq = %{$st_match_f};
  while (my($sequence_type, $freq) = each(%{$st_part_match_f})) {
    my $nearest_match_frequency = ( $st_nearest_match_freq{$sequence_type} || 0 );
    $st_nearest_match_freq{$sequence_type} = $nearest_match_frequency + $freq;
  }
  
  # if $num_loci is in $st_match_freq vals, return that, otherwise return lowest numbered sequence type
  while (my($sequence_type, $freq) = each(%st_match_freq)) {
    if ($freq == $num_loci) {
      return $sequence_type;
    }
  }
  my $best_sequence_type;
  if ( $self->report_lowest_st ){

    $best_sequence_type = min (keys %st_nearest_match_freq);
  }
  else {
    # This reduce takes pairs of sequence types and compares them.  It looks
    # for the ST with the highest number of matching alleles; if two matches
    # are just as good, it picks the ST with the smaller number.
    $best_sequence_type = reduce {
      if ( $st_nearest_match_freq{$a} > $st_nearest_match_freq{$b} ) {
        $a;
      } elsif ( $st_nearest_match_freq{$a} < $st_nearest_match_freq{$b} ) {
        $b;
      } else {
        min ($a, $b);
      }
    } keys %st_nearest_match_freq;
  }

  $self->nearest_sequence_type($best_sequence_type);
  return undef;	
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
