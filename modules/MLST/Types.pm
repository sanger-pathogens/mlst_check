package MLST::Types;
use Moose;
use Moose::Util::TypeConstraints;
use MLST::Validate::Executable;
use MLST::Validate::File;

subtype 'MLST::Executable',
  as 'Str',
  where { MLST::Validate::Executable->new()->does_executable_exist($_) };

subtype 'MLST::File',
  as 'Str',
  where { MLST::Validate::File->new()->does_file_exist($_) };

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;
1;