#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::DatabaseSettings');
}
note("There is an XML file from pubMLST which contains metadata such as links to all of the profiles and their associated alleles for each species. Check that this data can be parsed correctly.");

ok((my $database_settings = Bio::MLST::DatabaseSettings->new(filename     => 't/data/overall_databases.xml')), 'Initialise pubMLST database XML parser.');
ok((my $settings  = $database_settings->settings), 'Get the metadata for all of the MLST schemes.');

is($settings->{"Bordetella spp."}->{profiles}, "t/data/bordetella.txt", 'Given a known MLST scheme Bordetella, retrieve the location of the profile file.');
is($settings->{"Bordetella spp."}->{alleles}->[0],"t/data/abc.fas", 'Lookup the Bordetella file location for an allele.'); 
is($settings->{"Bordetella spp."}->{alleles}->[1],"t/data/bbb.fas", 'Lookup the Bordetella file location for another allele.');

note("Some Genus have more than 1 scheme and are suffixed with a number.");
is($settings->{"Homo sapiens#1"}->{profiles}, "t/data/homo_sapiens.txt", 'Given an MLST scheme with a number at the end of the species, get the location of the profile file.');
is($settings->{"Homo sapiens#1"}->{alleles}->[0],"t/data/ddd.fas", 'Lookup a scheme with a suffix number and get an allele file location.'); 
is($settings->{"Homo sapiens#1"}->{alleles}->[1],"t/data/eee.fas", 'Lookup a scheme with a suffix number and get another allele file location.');

done_testing();
