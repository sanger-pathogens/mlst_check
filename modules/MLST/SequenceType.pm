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

has '_allele_to_number' => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build__allele_to_number' ); 
has '_profiles'          => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build__profiles' ); 


sub _build__profiles
{
  my($self) = @_;
  my @profile ;
  open(my $fh, $self->profiles_filename) or die "Couldnt open profile: ".$self->profiles_filename."\n";
  while(<$fh>)
  {
    chomp;
    $line = $_;
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
  
  for(my $row = 1; $row < @{$self->_profiles}; $row++)
  {
    my @current_row = @{$self->_profiles->[$row]};
    for(my $col = 1; $col< @current_row -1; $col++)
    {
      return undef if(!defined($self->allele_to_number->{$header_row[$col]}) );
      
      # keep a running total of how many match so you can out put a closest match
      xxxxx
      return next if($self->allele_to_number->{$header_row[$col]} != $current_row[$col]);
    }
  }

  return undef;	
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
