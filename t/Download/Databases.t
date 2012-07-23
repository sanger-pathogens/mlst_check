#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './modules') }
BEGIN {
    use Test::Most;
    use_ok('MLST::DatabaseSettings');
    use_ok('MLST::Download::Databases');
}

my $destination_directory_obj = File::Temp->newdir(CLEANUP =>1);
my $destination_directory = $destination_directory_obj->dirname();

ok((my $database_settings = MLST::DatabaseSettings->new(filename => 'config/test/database.json')->settings),"get config file settings");

ok((my $databases = MLST::Download::Databases->new(
  site_attributes => $database_settings,
  base_directory  => $destination_directory
)), 'download databases initialisation');
ok($databases->update(),'download all databases');


ok((-e $destination_directory.'/ucc/Escherichia_coli/bbb.fas'));
ok((-e $destination_directory.'/ucc/Escherichia_coli/ccc.fas'));
ok((-e $destination_directory.'/ucc/Escherichia_coli/ddd.fas'));
ok((-e $destination_directory.'/ucc/Escherichia_coli/eee.fas'));

ok((-e $destination_directory.'/ucc/Homo_sapiens/fff.fas'));
ok((-e $destination_directory.'/ucc/Homo_sapiens/ggg.fas'));
ok((-e $destination_directory.'/ucc/Homo_sapiens/hhh.fas'));
ok((-e $destination_directory.'/ucc/Homo_sapiens/iii.fas'));

ok((-e $destination_directory.'/pasteur/BBB_CCC/bbb.fas'));
ok((-e $destination_directory.'/pasteur/BBB_CCC/eee.fas'));

ok((-e $destination_directory.'/pasteur/Homo_sapiens/fff.fas'));
ok((-e $destination_directory.'/pasteur/Homo_sapiens/ggg.fas'));
ok((-e $destination_directory.'/pasteur/Homo_sapiens/hhh.fas'));
ok((-e $destination_directory.'/pasteur/Homo_sapiens/iii.fas'));

done_testing();

