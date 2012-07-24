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
use Parallel::ForkManager;

has 'databases_attributes' => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'base_directory'       => ( is => 'ro', isa => 'Str',     required => 1 );

has 'parallel_processes'   => ( is => 'ro', isa => 'Int',     default => 4 );

sub update
{
  my($self) = @_;
  my $pm = new Parallel::ForkManager($self->parallel_processes); 
  for my $species (keys %{$self->databases_attributes})
  {
    $pm->start and next; # do the fork
    my $database = MLST::Download::Database->new(
      species => $species,
      database_attributes => $self->databases_attributes->{$species},
      base_directory      => join('/',($self->base_directory))
    );
    $database->update();
    $pm->finish; # do the exit in the child process
  }
  $pm->wait_all_children;
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
