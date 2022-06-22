package Bio::MLST::Download::Downloadable;
# ABSTRACT: Moose Role to download everything data

=head1 SYNOPSIS

Moose Role to download everything data

   with 'Bio::MLST::Download::Downloadable';

=head1 SEE ALSO

=for :list
* L<Bio::MLST::Download::Database>
* L<Bio::MLST::Download::Databases>

=cut


use Moose::Role;
use File::Copy;
use File::Basename;
use LWP::Simple;
use File::Path 2.06 qw(make_path);

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
    my $status = getstore($filename, join('/',($destination_directory,$self->_get_filename_from_url($filename))));
    die "Something went wrong, got a $status status code" if is_error($status);
  }
  1;
}

sub _get_filename_from_url
{
  my ($url) = @_;
  if ($url =~ m!/([^/]+)$!)
  {
    my ($original_filename) = $1;
    if ($original_filename eq "profiles_csv") {
      $url =~ m!/pubmlst_([^_]+)!;
      return "$1.txt"
    }
    elsif ($original_filename eq "alleles_fasta") {
      $url =~ m!/loci/([^/]+)!;
      return "$1.tfa"
    }
    else {
      die "Unexpected filename obtained from URL: $original_filename"
    }
  }

  return int(rand(10000)).".tfa";
}

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

no Moose;
1;

