=head1 NAME

Executable - Validates the executable is available in the path before running it

=head1 SYNOPSIS

=cut

package MLST::Validate::Executable;
use Moose;
use File::Which;

sub does_executable_exist
{
  my($self, $exec) = @_;

  my @full_paths_to_exec = which($exec);
  return 0 if(@full_paths_to_exec == 0);
  
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;