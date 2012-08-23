=head1 NAME
Bio::MLST::Types
=head1 SYNOPSIS
Moose types to use for validation
=head1 CONTACT
path-help@sanger.ac.uk
=cut

package Bio::MLST::Types;
use Moose;
use Moose::Util::TypeConstraints;
use Bio::MLST::Validate::Executable;
use Bio::MLST::Validate::File;

subtype 'Bio::MLST::Executable',
  as 'Str',
  where { Bio::MLST::Validate::Executable->new()->does_executable_exist($_) };

subtype 'Bio::MLST::File',
  as 'Str',
  where { Bio::MLST::Validate::File->new()->does_file_exist($_) };

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;
1;
