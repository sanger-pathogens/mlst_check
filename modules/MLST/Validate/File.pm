=head1 NAME

File - Does a file exist?

=head1 SYNOPSIS

=cut

package MLST::Validate::File;
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