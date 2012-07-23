=head1 NAME

DatabaseSettings - read in a JSON file of settings and return a hash with the values

=head1 SYNOPSIS

use MLST::DatabaseSettings;
my $database_settings = MLST::DatabaseSettings->new(
  filename     => 'filename'
);
$database_settings->settings;
=cut

package MLST::DatabaseSettings;
use Moose;
use JSON;

has 'filename'          => ( is => 'ro', isa => 'Str', required => 1 );

sub settings
{
  my($self) = @_;
  local $/=undef;
  open( my $fh, $self->filename );
  my $json_text   = <$fh>;
  return decode_json( $json_text );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
