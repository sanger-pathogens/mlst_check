=head1 NAME

Role to download everything data

=head1 SYNOPSIS

with 'MLST::Download::Downloadable';

=cut

package MLST::Download::Downloadable;
use Moose::Role;
use File::Copy;
use File::Basename;
use LWP::Simple;

sub _download_file
{
  my ($self, $filename,$destination_directory) = @_;
  
  # copy if its on the same filesystem
  if(-e $filename)
  {
    copy($filename, $destination_directory);
  }
  else
  {
    getstore($filename, join('/',($destination_directory,$self->_get_filename_from_url($filename))));
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
  
  return int(rand(10000)).".tfa";
}

no Moose;
1;

