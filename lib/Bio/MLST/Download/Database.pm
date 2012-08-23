=head1 NAME
Bio::MLST::Download::Database
=head1 SYNOPSIS
Represents a single genus-species database on a single species
=head1 DESCRIPTION

use Bio::MLST::Download::Database;
my $database = Bio::MLST::Download::Database->new(

  database_attributes => \%database_attributes,
  base_directory => '/path/to/abc'
);
$database->update;
=head1 CONTACT
path-help@sanger.ac.uk
=cut

package Bio::MLST::Download::Database;
use File::Path qw(make_path);
use Moose;

with 'Bio::MLST::Download::Downloadable';

has 'database_attributes'  => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'base_directory'       => ( is => 'ro', isa => 'Str',     required => 1 );
has 'species'              => ( is => 'ro', isa => 'Str',     required => 1 );

has 'destination_directory' => ( is => 'ro', isa => 'Str',     lazy => 1, builder => '_build_destination_directory' );

sub _build_destination_directory
{
  my ($self) = @_;
  my $destination_directory = join('/',($self->base_directory,$self->_sub_directory));
  make_path($destination_directory);
  make_path(join('/',($destination_directory,'alleles')));
  make_path(join('/',($destination_directory,'profiles')));
  return $destination_directory;
}

sub _sub_directory
{
  my ($self) = @_;
  my $combined_name = join('_',($self->species));
  $combined_name =~ s!\.$!!gi;
  $combined_name =~ s!\W!_!gi;
  return $combined_name;
}
sub update
{
  my ($self) = @_;

  for my $allele_file (@{$self->database_attributes->{alleles}})
  {
    $self->_download_file($allele_file,join('/',($self->destination_directory,'alleles')));
  }
  $self->_download_file($self->database_attributes->{profiles},join('/',($self->destination_directory,'profiles')));

  1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
