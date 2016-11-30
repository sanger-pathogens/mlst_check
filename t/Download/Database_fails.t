#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use Test::MockModule;
use Test::Exception;
use HTTP::Status;
use File::Touch qw(touch);
use File::Path qw(make_path);

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
}

note('Occasionally downloading the database from a remote server fails, and we have to handle this in a graceful manner which doesnt mess up existing data.');

my $lwp = new Test::MockModule('LWP::Simple');
$lwp->mock(getstore => sub { return RC_NOT_FOUND });
$lwp->mock(is_success => sub { return 0 });
use_ok('Bio::MLST::Download::Database');
use_ok('Bio::MLST::DatabaseSettings');
use_ok('Bio::MLST::Download::Databases');

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

# Create fake database contents to check if they are overwritten by update
make_path($destination_directory.'/Bordetella_spp/profiles/');
touch($destination_directory.'/Bordetella_spp/profiles/file_to_be_kept.txt');

my $database = Bio::MLST::Download::Database->new(
  database_attributes => { 
      alleles => ['t/data/abc.fas','t/data/efg.fas'], 
      profiles => 't/data/bordetella.txt'
    },
  base_directory => $destination_directory,
  species => "ABC EFG#1"
  );

dies_ok( sub { $database->_download_file("http://example.com", "/tmp/not/actually/a/path") }, "Mock downloading a missing file - IGNORE Prototype warnings above and below");

my $database_settings = Bio::MLST::DatabaseSettings->new(filename => 't/data/missing_web_database.xml')->settings;
my $databases = Bio::MLST::Download::Databases->new(
  databases_attributes => $database_settings,
  base_directory  => $destination_directory
);
dies_ok( sub { $databases->update() },'Fails gracefully if there is a problem downloading the new database');

ok((-e $destination_directory.'/Bordetella_spp/profiles/file_to_be_kept.txt'), "Did not overwrite existing data");

done_testing();
