package Bio::MLST::Validate::File;
# ABSTRACT: Check to see if a file exists. For validation when classes have input files.

=head1 SYNOPSIS

Check to see if a file exists. For validation when classes have input files.

=method does_file_exist

Check to see if a file exists. For validation when classes have input files.

=cut

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
