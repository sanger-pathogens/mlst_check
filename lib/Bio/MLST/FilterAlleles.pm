package Bio::MLST::FilterAlleles;
# ABSTRACT: Filter Alleles

=head1 SYNOPSIS

FilterAlleles.pm - Filter header row  from profile to remove non-alleles

=cut

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(only_keep_alleles is_metadata);

# A list of column headings in a profile file which
# can be assumed not to be allele names.  If this list
# gets much longer we should have a rethink about
# getting a whitelist of alleles either based on the
# contents of the alleles directory or from the
# config file downloaded from the internet.
my @allele_blacklist = (
  'CC',
  'Lineage',
  'ST',
  'clonal_complex',
  'mlst_clade',
  'species'
);

sub is_metadata
{
  my ($column_heading) = @_;
  return grep( /^$column_heading$/, @allele_blacklist );
}

sub only_keep_alleles
{
  my ($alleles) = @_;
  my @alleles_to_keep = ();
  for my $allele (@$alleles) {
    push( @alleles_to_keep, $allele ) unless is_metadata($allele);
  }
  return \@alleles_to_keep;
}

1;
