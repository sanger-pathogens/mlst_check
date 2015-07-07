package Bio::MLST::Validate::Executable;

# ABSTRACT: Validates the executable is available in the path before running it.

=head1 SYNOPSIS

Validates the executable is available in the path before running it.

   use Bio::MLST::Validate::Executable;
   Bio::MLST::Validate::Executable
      ->new()
      ->does_executable_exist('abc');

=method does_executable_exist

Check to see if an executable is available in the current users PATH.

=cut

use Moose;
use File::Which;

sub does_executable_exist
{
  my($self, $executable) = @_;
  if (defined $executable and -x $executable) {
    return 1;
  } elsif ( which($executable) ) {
    return 1;
  } else {
    return 0;
  }
}

sub preferred_executable
{
  my($self, $executable, $defaults) = @_;
  if ($self->does_executable_exist($executable)) {
    return $executable;
  }
  if (defined $executable) {
    warn "Could not find executable '".$executable."', attempting to use defaults\n";
  }
  for my $default (@{$defaults}) {
    if ($self->does_executable_exist($default)) {
      return $default;
    }
  }
  die "Could not find any usable default executables in '".join(", ", @{$defaults})."'\n";
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
