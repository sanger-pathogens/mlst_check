package Bio::MLST::Validate::Resource;
# ABSTRACT: Check to see if a file exists or if a uri is valid. For validation when classes have input files which may be local or on the web.

=head1 SYNOPSIS

Check to see if a file exists or if a uri is valid. For validation when classes have input files which may be local or on the web.

=method does_file_exist

Check to see if a file exists or if a uri is valid. For validation when classes have input files which may be local or on the web.

=cut

use Moose;
use Regexp::Common qw /URI/;

sub does_resource_exist
{
  my($self, $resource) = @_;
  
  return 1 if($RE{URI}->matches($resource));
  
  return 1 if(-e $resource);
  
  return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
