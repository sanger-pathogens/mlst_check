=head1 NAME

SequenceType - Take in a list of matched alleles and look up the sequence type from the profile

=head1 SYNOPSIS

use MLST::SequenceType;

my $st = MLST::SequenceType->new(
  profiles_filename => 't/data/Escherichia_coli_1/profiles/escherichia_coli.txt',
  sequence_names => ['adk-2','purA-3','recA-1']
);
$st->sequence_type();


=cut

package MLST::SequenceType;
use Moose;

has 'profiles_filename' => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'sequence_names'    => ( is => 'ro', isa => 'ArrayRef', required => 1 ); 

has '_allele_to_number'  => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build__allele_to_number' ); 
has '_profiles'          => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__profiles' );

has 'nearest_sequence_type' => ( is => 'rw', isa => 'Maybe[Int]');


sub _build__profiles
{
  my($self) = @_;
  my @profile ;
  open(my $fh, $self->profiles_filename) or die "Couldnt open profile: ".$self->profiles_filename."\n";
  while(<$fh>)
  {
    chomp;
    my $line = $_;
    my @profile_row = split("\t",$line);
    push(@profile, \@profile_row);
  }
  
  return \@profile;
}

sub _build__allele_to_number
{
  my($self) = @_;
  my %allele_to_number;
  
  for my $sequence_name (@{$self->sequence_names})
  {
    my @sequence_name_details = split('-',$sequence_name);
    $allele_to_number{$sequence_name_details[0]} = $sequence_name_details[1];
  }
  
  return \%allele_to_number;
}

sub sequence_type
{
  my($self) = @_;
  
  my @header_row = @{$self->_profiles->[0]};
  my $num_loci = 0;
  my %sequence_type_freq;
  
  for(my $row = 1; $row < @{$self->_profiles}; $row++)
  {
    my @current_row = @{$self->_profiles->[$row]};
    for(my $col = 0; $col< @current_row; $col++)
    {
      next if($header_row[$col] eq "ST" || $header_row[$col] eq "clonal_complex");
      $num_loci++ if($row == 1);
       
      next if(!defined($self->_allele_to_number->{$header_row[$col]}) );
      next if($self->_allele_to_number->{$header_row[$col]} != $current_row[$col]);
      
      $sequence_type_freq{$current_row[0]}++;
    }
  }
  
  return $self->_get_sequence_type_or_set_nearest_match(\%sequence_type_freq, $num_loci);	
}

sub _get_sequence_type_or_set_nearest_match
{
  my($self,$sequence_type_f, $num_loci) = @_;
  my %sequence_type_freq = %{$sequence_type_f};
  
  for my $sequence_type (sort { $sequence_type_freq{$b} <=> $sequence_type_freq{$a} } keys %sequence_type_freq) 
  {
    if($sequence_type_freq{$sequence_type} == $num_loci)
    {
      return $sequence_type;
    }
    else
    {
      $self->nearest_sequence_type($sequence_type);
      return undef;	
    }
  }
  return undef;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
