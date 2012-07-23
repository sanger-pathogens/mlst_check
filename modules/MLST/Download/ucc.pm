=head1 NAME

ucc - site specific code to download everything required for a database

=head1 SYNOPSIS

use MLST::Download::ucc;
my $database = MLST::Download::ucc->new(
  database_attributes => \%database_attributes,
  destination_directory => '/path/to/abc'
);
$database->update;
=cut

package MLST::Download::ucc;
use Moose;
use File::Copy;
use File::Basename;
use LWP::Simple;

has 'database_attributes'   => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'destination_directory' => ( is => 'ro', isa => 'Str',     required => 1 );

sub update
{
  my ($self) = @_;

  for my $allele_file (@{$self->database_attributes->{allele_files}})
  {
    $self->_download_file($allele_file);
  }
  for my $strain_file (@{$self->database_attributes->{strain_files}})
  {
    $self->_download_file($strain_file);
  }
  1;
}

sub _download_file
{
  my ($self, $filename) = @_;
  
  # copy if its on the same filesystem
  if(-e $filename)
  {
    copy($filename, $self->destination_directory);
  }
  else
  {
    getstore($filename, join('/',($self->destination_directory,$self->_get_filename_from_url($filename))));
  }
  1;
}

sub _get_filename_from_url
{
  my ($self, $filename) = @_;
  if($filename =~ m!/([^/]+)$!)
  {
    return $1;
  }
  
  return int(rand(10000)).".fa";
}

no Moose;
1;

