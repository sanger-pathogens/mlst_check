use strict;
use warnings;
use Cwd;
use File::Spec;
use File::Which;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::Validate::Executable');
}

my $current_dir = getcwd();

my $not_defined;
my $does_not_exist = $current_dir.'/t/data/fake_executables/does_not_exist.sh';
my $not_executable = $current_dir.'/t/data/fake_executables/not_executable.sh';
my $executable = $current_dir.'/t/data/fake_executables/executable.sh';
my $another_executable = $current_dir.'/t/data/fake_executables/another_executable.sh';
my $in_path = 'perl';

my $validator = Bio::MLST::Validate::Executable->new();

{
  my @warnings;
  local $SIG{__WARN__} = sub { push( @warnings, @_) };
  dies_ok( sub { $validator->preferred_executable($not_defined, []) }, "Not defined, no defaults");
  dies_ok( sub { $validator->preferred_executable($not_defined, [$does_not_exist]) }, "Not defined, default doesn't exist" );
  dies_ok( sub { $validator->preferred_executable($not_defined, [$does_not_exist, $not_executable]) }, "Not defined, bad defaults");
  dies_ok( sub { $validator->preferred_executable($not_executable, [$does_not_exist]) }, "Not executable, doesn't exist");
  dies_ok( sub { $validator->preferred_executable($does_not_exist, [$not_executable]) }, "Doesn't exist, not executable");
  is(@warnings, 2, "Correct number of warnings");
}

is($validator->preferred_executable($executable, []), $executable, "Good executable");
is($validator->preferred_executable($executable, [$does_not_exist]), $executable, "Good executable, bad default");
is($validator->preferred_executable($executable, [$another_executable]), $executable, "Good executable, good default");
is($validator->preferred_executable($executable, [$not_executable, $another_executable]), $executable, "Good executable, mixed defaults");

{
  my @warnings;
  local $SIG{__WARN__} = sub { push( @warnings, @_ )};
  is($validator->preferred_executable($not_executable, [$executable, $another_executable]), $executable, "Not executable, good defaults");
  is($validator->preferred_executable($not_defined, [$executable, $another_executable]), $executable, "Not defined, good defaults");
  is($validator->preferred_executable($not_defined, [$another_executable, $executable]), $another_executable, "Reversed good defaults");
  is($validator->preferred_executable($not_executable, [$does_not_exist, $executable, $another_executable]), $executable, "Bad executable, mixed defaults");
  is($validator->preferred_executable($not_executable, [$executable, $does_not_exist, $another_executable]), $executable, "Bad executable, more mixed defaults");
  is(@warnings, 3, "Check expected warnings");
}

is($validator->preferred_executable($executable, [$in_path]), $executable, "Good executable, default in PATH");
is($validator->preferred_executable($in_path, [$executable]), $in_path, "Executable in PATH, good default");
is($validator->preferred_executable($in_path, [$does_not_exist]), $in_path, "Executable in PATH, bad default");

done_testing();
