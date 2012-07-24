=head1 NAME

Databases - represents multiple databases of species

=head1 SYNOPSIS

use MLST::Download::Databases;
my $databases = MLST::Download::Databases->new(
  databases_attributes     => \@databases_attributes
  base_directory => '/path/to/dir'
);
$databases->update;
=cut

package MLST::Download::Databases;
use Moose;
use MLST::Download::Database;

has 'databases_attributes' => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'base_directory'       => ( is => 'ro', isa => 'Str',     required => 1 );

sub update
{
  my($self) = @_;
  for my $species (keys %{$self->databases_attributes})
  {
    my $database = MLST::Download::Database->new(
      species => $species,
      database_attributes => $self->databases_attributes->{$species},
      base_directory      => join('/',($self->base_directory))
    );
    $database->update();
  }
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
