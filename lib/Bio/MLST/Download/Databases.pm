package Bio::MLST::Download::Databases;
# ABSTRACT: Represents multiple databases of species

=head1 SYNOPSIS

Represents multiple databases of species

   use Bio::MLST::Download::Databases;
   my $databases = Bio::MLST::Download::Databases->new(
     databases_attributes     => \@databases_attributes
     base_directory => '/path/to/dir'
   );
   $databases->update;

=method update

Download the database files.

=head1 SEE ALSO

=for :list
* L<Bio::MLST::Download::Downloadable>

=cut

use Moose;
use Bio::MLST::Download::Database;
use Parallel::ForkManager;

has 'databases_attributes' => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'base_directory'       => ( is => 'ro', isa => 'Str',     required => 1 );

has 'parallel_processes'   => ( is => 'ro', isa => 'Int',     default => 4 );

has '_species_to_exclude'  => ( is => 'ro', isa => 'Str',     default => 'Pediococcus' );

sub update
{
  my($self) = @_;
  my $pm = new Parallel::ForkManager($self->parallel_processes); 
  for my $species (keys %{$self->databases_attributes})
  {
    $pm->start and next; # do the fork
    my $species_to_exclude = $self->_species_to_exclude;
    next if($species =~ /$species_to_exclude/i);
    my $database = Bio::MLST::Download::Database->new(
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
