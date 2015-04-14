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

use Try::Tiny;
use File::Copy qw(move);
use File::Path qw(make_path rmtree);
use POSIX qw(strftime);

has 'databases_attributes' => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'base_directory'       => ( is => 'ro', isa => 'Str',     required => 1 );

has 'parallel_processes'   => ( is => 'ro', isa => 'Int',     default => 0 );

has '_species_to_exclude'  => ( is => 'ro', isa => 'Str',     default => 'Pediococcus' );

sub update {
   my($self) = @_;
   my $paths_to_database_updates = $self->databases_attributes;
   my $species_to_exclude = $self->_species_to_exclude;
   my $temp_folder = strftime "temp_%Y%m%d%H%M%S", localtime; # e.g. temp_20150402102622
   my $staging_directory = join('/', ($self->base_directory, 'staging', $temp_folder));
   try {
     $self->_download_to_staging($species_to_exclude,
                                 $paths_to_database_updates,
                                 $staging_directory);
   } catch {
     my $original_error = $_ || 'Unknown error';
     die "Sorry, there was a problem updating the database.  ",
         "Some of the updates have been downloaded to $staging_directory ",
         "but this is likely to be incomplete\n",
         "The original message was as follows:\n$original_error";
   };
   my $production_directory = join('/',($self->base_directory));
   $self->_update_all_from_staging($staging_directory,
                                   $production_directory);
   rmtree($staging_directory);
   1;
}

sub _download_to_staging
{
  my($self, $species_to_exclude, $paths_to_downloads, $staging_directory) = @_;
  my $pm = new Parallel::ForkManager($self->parallel_processes);

  for my $species (keys %{$paths_to_downloads})
  {
    $pm->start and next; # do the fork
    if($species =~ /$species_to_exclude/i) {
      $pm->finish; # exit child process
      next;
    }

    my $database = Bio::MLST::Download::Database->new(
      species => $species,
      database_attributes => $paths_to_downloads->{$species},
      base_directory      => $staging_directory
    );
    $database->update();
    $pm->finish; # exit the child process
  }
  $pm->wait_all_children;
  1;
}

sub _get_sub_directories
{
  my($self, $parent_folder) = @_;
  return [] if (! -d $parent_folder);
  opendir(my $FOLDER_HANDLE, $parent_folder);
  my @folder_contents = readdir($FOLDER_HANDLE);
  my @real_contents = grep { ! /^\.$/ and ! /^\.\.$/ } @folder_contents; # Remove '.' and '..' directories
  my @child_directories = grep { -d "$parent_folder/$_" } @real_contents;
  return \@child_directories;
}

sub _update_all_from_staging
{
  my($self, $staging_directory, $production_directory) = @_;

  my $species_directories = $self->_get_sub_directories($staging_directory);

  foreach my $species_directory (@{$species_directories}){
    my $species_staging_path = join("/", ($staging_directory, $species_directory));
    my $species_production_path = join("/", ($production_directory, $species_directory));
    if (-d $species_staging_path ) {
      rmtree($species_production_path) if ( -d $species_production_path );
      move($species_staging_path, $species_production_path);
    }
  }
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
