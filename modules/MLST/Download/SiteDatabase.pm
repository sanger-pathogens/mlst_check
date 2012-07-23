=head1 NAME

SiteDatabase - represents a single genus-species database on a single site

=head1 SYNOPSIS

use MLST::Download::SiteDatabase;
my $database = MLST::Download::SiteDatabase->new(
  site     => 'ucc',
  database_attributes => \%database_attributes,
  base_directory => '/path/to/abc'
);
$database->update;
=cut

package MLST::Download::SiteDatabase;
use File::Path qw(make_path);
use Moose;

has 'site'                 => ( is => 'ro', isa => 'Str',     required => 1 );
has 'database_attributes'  => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'base_directory'       => ( is => 'ro', isa => 'Str',     required => 1 );

has 'destination_directory' => ( is => 'ro', isa => 'Str',     lazy => 1, builder => '_build_destination_directory' );

sub _build_destination_directory
{
  my ($self) = @_;
  my $destination_directory = join('/',($self->base_directory,$self->_sub_directory));
  make_path($destination_directory);
  return $destination_directory;
}

sub _sub_directory
{
  my ($self) = @_;
  my $combined_name = join('_',($self->database_attributes->{genus},$self->database_attributes->{species}));
  $combined_name =~ s!\W!!gi;
  return $combined_name;
}

sub update
{
  my ($self) = @_;
  $self->_import_site_module;
  
  $self->_site_module->new( 
    destination_directory => $self->destination_directory,
    database_attributes => $self->database_attributes
  )->update();
}

sub _import_site_module
{
  my ($self) = @_;
  my $module_name = $self->_site_module;
  my  $module_file_name = $module_name;
  $module_file_name =~ s|::|/|g;
  require $module_file_name . '.pm';
  $module_name->import();
}

sub _site_module
{
  my ($self) = @_;
  'MLST::Download::'.$self->site.'';
}


no Moose;
1;
