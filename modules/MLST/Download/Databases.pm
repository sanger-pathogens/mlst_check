=head1 NAME

Databases - represents a multiple genus-species databases on multiple sites

=head1 SYNOPSIS

use MLST::Download::Databases;
my $databases = MLST::Download::Databases->new(
  site_attributes     => \@site_attributes
);
$databases->update;
=cut

package MLST::Download::Databases;
use Moose;
use MLST::Download::SiteDatabases;

has 'site_attributes' => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'base_directory'  => ( is => 'ro', isa => 'Str',     required => 1 );

sub update
{
  my($self) = @_;
  for my $site (keys %{$self->site_attributes})
  {
    my $database = MLST::Download::SiteDatabases->new(
      site                => $site,
      multiple_database_attributes => $self->site_attributes->{$site},
      base_directory      => join('/',($self->base_directory,$site))
    );
    $database->update();
  }
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
