=head1 NAME

Bio::MLST::Databases

=head1 SYNOPSIS
List available MLST databases

=head1 DESCRIPTION

use Bio::MLST::Databases;

my $mlst_dbs = Bio::MLST::Databases->new(
  base_directory => '/path/to/databases',
);
$mlst_dbs->print_db_list;
=head1 CONTACT
path-help@sanger.ac.uk
=cut

package Bio::MLST::Databases;
use Moose;

has 'base_directory'    => ( is => 'ro', isa => 'Str',      required => 1 );

has 'database_names'    => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_builder_database_names' );

sub _builder_database_names
{
  my($self) = @_;
  my @only_directories;
  opendir(my $dh,$self->base_directory);
  my @database_names = grep { /^[^\.]/ } readdir($dh);

  for my $file_or_dir_name (sort(@database_names))
  {
    next unless(-d ($self->base_directory.'/'.$file_or_dir_name));
    push(@only_directories, $file_or_dir_name);
  }
  
  return \@only_directories;
}

sub print_db_list
{
  my($self) = @_;
  for my $database_name (@{$self->database_names})
  {
    $database_name =~ s!_! !g;
    print $database_name."\n";
  }
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
