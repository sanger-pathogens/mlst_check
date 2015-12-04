=head NAME

FilterAlleles.pm - Filter header row  from profile to remove non-alleles

=head 1 SYNOPSIS

=cut

package Bio::MLST::FilterAlleles;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(only_keep_alleles);

my @allele_blacklist = (
#  'CC',
#  'Lineage',
  'ST',
  'clonal_complex',
  'mlst_clade',
#  'species'
);

sub only_keep_alleles
{
  my ($alleles) = @_;
  my @alleles_to_keep = ();
  for my $allele (@$alleles) {
    push( @alleles_to_keep, $allele ) unless ($allele ~~ @allele_blacklist);
  }
  return \@alleles_to_keep;
}

1;
