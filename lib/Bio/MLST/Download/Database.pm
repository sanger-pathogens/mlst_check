package Bio::MLST::Download::Database;
# ABSTRACT: Represents a single genus-species database on a single species

=head1 SYNOPSIS

Represents a single genus-species database on a single species.

   use Bio::MLST::Download::Database;
   my $database = Bio::MLST::Download::Database->new(
   
     database_attributes => \%database_attributes,
     base_directory => '/path/to/abc'
   );
   $database->update;

=method update

Download the database files.

=head1 SEE ALSO

=for :list
* L<Bio::MLST::Download::Downloadable>

=cut


use Moose;

with 'Bio::MLST::Download::Downloadable';

has 'database_attributes'  => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'base_directory'       => ( is => 'ro', isa => 'Str',     required => 1 );
has 'species'              => ( is => 'ro', isa => 'Str',     required => 1 );

has 'destination_directory' => ( is => 'ro', isa => 'Str',     lazy => 1, builder => '_build_destination_directory' );


sub update
{
  my ($self) = @_;

  for my $allele_file (@{$self->database_attributes->{alleles}})
  {
    $self->_download_file($allele_file,join('/',($self->destination_directory,'alleles')));
  }
  $self->_download_file($self->database_attributes->{profiles},join('/',($self->destination_directory,'profiles')));

  1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
