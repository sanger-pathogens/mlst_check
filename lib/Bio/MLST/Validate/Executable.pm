=head1 NAME
Bio::MLST::Validate::Executable
=head1 SYNOPSIS
Validates the executable is available in the path before running it

=head1 DESCRIPTION
Check to see if an executable is available in the current users PATH.
=head1 CONTACT
path-help@sanger.ac.uk
=cut

package Bio::MLST::Validate::Executable;
use Moose;
use File::Which;

sub does_executable_exist
{
  my($self, $exec) = @_;
  # if its a full path then skip over it
  return 1 if($exec =~ m!/!);

  my @full_paths_to_exec = which($exec);
  return 0 if(@full_paths_to_exec == 0);
  
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
