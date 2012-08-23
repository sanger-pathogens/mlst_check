=head1 NAME
Bio::MLST::Validate::File
=head1 SYNOPSIS
Does a file exist

=head1 DESCRIPTION
Check to see if a file exists. For validation when classes have input files.
=head1 CONTACT
path-help@sanger.ac.uk
=cut

package Bio::MLST::Validate::File;
use Moose;

sub does_file_exist
{
  my($self, $file) = @_;
  return 1 if(-e $file);
  
  return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
