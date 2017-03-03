package Bio::MLST::DatabaseSettings;
# ABSTRACT: Read in an XML file of settings and return a hash with the values.

=head1 SYNOPSIS

Read in an XML file of settings and return a hash with the values.

   use Bio::MLST::DatabaseSettings;
   my $database_settings = Bio::MLST::DatabaseSettings->new(
     filename     => 'filename'
   );
   $database_settings->settings;

=method settings

Returns a hash containing the settings for the database, separated by species name, and giving alleles and the profile location.

=cut

use Moose;
use XML::LibXML;
use LWP::UserAgent;
use HTTP::Request;

has 'filename'          => ( is => 'ro', isa => 'Str', required => 1 );

sub generate_dom
{
	my($self, $location ) = @_;
	
	# local file and remote files need to be treated differently
	if ( !( $location =~ /(http|ftp)/ ) ) {
		return XML::LibXML->load_xml( location => $location );	
	}
	else
	{
		# its a remote file so download content
	        my $ua = LWP::UserAgent->new;
		if(defined($ENV{HTTPS_PROXY}))
		{
	        	$ua->proxy( [ 'http', 'https' ], $ENV{HTTPS_PROXY} );
		}
	        my $req = HTTP::Request->new( GET => $location );
	        my $res = $ua->request($req);
	        $res->is_success or die "Could not connect to $location\n";
		XML::LibXML->load_xml( string => $res->content );
	}
}

sub settings
{
  my($self) = @_;
  my %databases_attributes;
  
  my $dom = $self->generate_dom($self->filename);
  
  for my $species ($dom->findnodes('/data/species')) 
  {
    my $species_name = $self->_clean_string($species->firstChild()->data);

    $databases_attributes{$species_name}{profiles} = $self->_clean_string($species->findnodes('./mlst/database/profiles/url')->[0]->firstChild()->data);
    
    for my $allele ($species->findnodes('./mlst/database/loci/locus'))
    {
      if(! defined ($databases_attributes{$species_name}{alleles}) )
      {
        $databases_attributes{$species_name}{alleles} = [];
      }
      push(@{$databases_attributes{$species_name}{alleles}}, $self->_clean_string($allele->findnodes('./url')->[0]->firstChild()->data));
    }
  }
  return \%databases_attributes;
}


sub _clean_string
{
  my($self, $input_string) = @_;
  chomp($input_string);
  $input_string =~ s![\n\r\t]!!g;
  return $input_string;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
