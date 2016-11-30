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

note("Test the executables which the Perl code depends on. Really this is checking if blastn/makeblastdb available and runable.");

my $current_dir = getcwd();

my $not_defined;
my $does_not_exist     = $current_dir . '/t/data/fake_executables/does_not_exist.sh';
my $not_executable     = $current_dir . '/t/data/fake_executables/not_executable.sh';
my $executable         = $current_dir . '/t/data/fake_executables/executable.sh';
my $another_executable = $current_dir . '/t/data/fake_executables/another_executable.sh';
my $in_path            = 'perl';

my $validator = Bio::MLST::Validate::Executable->new();

{
    my @warnings;
    local $SIG{__WARN__} = sub { push( @warnings, @_ ) };
    dies_ok(
        sub { $validator->preferred_executable( $not_defined, [] ) },
        "The executable is not defined and theres no defaults, so it should die."
    );
    dies_ok(
        sub { $validator->preferred_executable( $not_defined, [$does_not_exist] ) },
        "The executable is not defined and the default executable doesnt exist, so it should die."
    );
    dies_ok(
        sub { $validator->preferred_executable( $not_defined, [ $does_not_exist, $not_executable ] ) },
        "The executable is not defined and the default executables doesnt exist or are not executable, so it should die."
    );
    dies_ok(
        sub { $validator->preferred_executable( $not_executable, [$does_not_exist] ) },
        "The executable is not executable and the default does not exist, so it should die."
    );
    dies_ok(
        sub { $validator->preferred_executable( $does_not_exist, [$not_executable] ) },
        "The executable does not exist and the default is not executable so it should die."
    );
    is( @warnings, 2, "There should be 2 warnings if the input executable and the default are problematic" );
}

note("The input executable is valid, but the defaults are not. Check that only the valid input executable is returned.");
is( $validator->preferred_executable( $executable, [] ),
    $executable, "Valid input executable and no defaults, so the valid input executable is chosen." );
is( $validator->preferred_executable( $executable, [$does_not_exist] ),
    $executable, "Valid input executable, where the default does not exist, so the valid input executable is chosen." );
is( $validator->preferred_executable( $executable, [$another_executable] ),
    $executable, "Valid input executable where the default is also valid, so the valid input executable is chosen." );
is( $validator->preferred_executable( $executable, [ $not_executable, $another_executable ] ),
    $executable, "Valid input executable, where the defaults contain good and bad executables, so the valid input executable is chosen." );

{
    my @warnings;
    local $SIG{__WARN__} = sub { push( @warnings, @_ ) };
    note("The input executable is not valid, but all of the defaults are, make sure the valid default gets chosen.");
    is( $validator->preferred_executable( $not_executable, [ $executable, $another_executable ] ),
        $executable, "The input executable is not executable, and all the defaults are valid, so choose the first default." );
    is( $validator->preferred_executable( $not_defined, [ $executable, $another_executable ] ),
        $executable, "The input executable is not defined, and all the defaults are valid, so choose the first default." );
    is( $validator->preferred_executable( $not_defined, [ $another_executable, $executable ] ),
        $another_executable,
        "The input executable is not defined, and all the defaults are valid, but reversed, so choose the first default." );
    is( $validator->preferred_executable( $not_executable, [ $does_not_exist, $executable, $another_executable ] ),
        $executable, "The input executable is not executable, and the first default is not valid, so choose the next valid default." );
    is( $validator->preferred_executable( $not_executable, [ $executable, $does_not_exist, $another_executable ] ),
        $executable, "The input executable is not executable, and one of the defaults does not exist so choose the first one that is valid." );
    is( @warnings, 3, "There should be 3 warning messages about choosing the executable" );
}

is( $validator->preferred_executable( $executable, [$in_path] ),        $executable, "Good executable, default in PATH." );
is( $validator->preferred_executable( $in_path,    [$executable] ),     $in_path,    "Executable in PATH, good default." );
is( $validator->preferred_executable( $in_path,    [$does_not_exist] ), $in_path,    "Executable in PATH, bad default." );

done_testing();
