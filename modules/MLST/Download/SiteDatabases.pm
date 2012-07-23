=head1 NAME

SiteDatabases - represents a multiple genus-species databases on a single site

=head1 SYNOPSIS

use MLST::Download::SiteDatabases;
my $database = MLST::Download::SiteDatabases->new(
  site     => 'ucc',
  multiple_database_attributes => \@database_attributes,
  base_directory => '/path/to/abc'
);
$database->update;
=cut

package MLST::Download::SiteDatabases;
use Moose;
use MLST::Download::SiteDatabase;

has 'site'                          => ( is => 'ro', isa => 'Str',      required => 1 );
has 'multiple_database_attributes'  => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'base_directory'                => ( is => 'ro', isa => 'Str',      required => 1 );

sub update
{
  my($self) = @_;
  for my $database_attributes (@{$self->multiple_database_attributes})
  {
    my $database = MLST::Download::SiteDatabase->new(
      site     => $self->site,
      database_attributes => $database_attributes,
      base_directory => $self->base_directory
    );
    $database->update();
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
