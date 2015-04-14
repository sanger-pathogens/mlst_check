package Bio::MLST::CDC::Convert;
# ABSTRACT: Take in a fasta file of emmST sequences and convert it into an MLST format

=head1 SYNOPSIS

ake in a fasta file of emmST sequences and convert it into an MLST format, producing an allele file, and a profile.

   use Bio::MLST::CDC::Convert;
   
   my $convert_fasta = Bio::MLST::CDC::Convert->new(
     species        => 'Streptococcus pyogenes emmST',
     input_file     => 't/data/CDC_emmST_partial.tfa',
     gene_name      => 'emmST',
     base_directory => '/path/to/output/dir'
     );
   $convert_fasta->create_mlst_files();

=method create_mlst_files

Create an allele file and a profile, in the MLST directory structure.

=cut


use Moose;
use File::Basename;
use File::Path qw(make_path);
use Bio::PrimarySeq;
use Bio::SeqIO;
use Bio::MLST::Types;
use Text::CSV;

with 'Bio::MLST::Download::Downloadable';

has 'species'          => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'input_file'       => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'gene_name'        => ( is => 'ro', isa => 'Str',          required => 1 ); 
has 'base_directory'   => ( is => 'ro', isa => 'Str',          required => 1 ); 

has 'destination_directory'   => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build_destination_directory' );
has '_output_allele_filename' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__output_allele_filename' ); 
has '_output_profile_filename' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__output_profile_filename' ); 

sub _build__output_allele_filename
{
  my ($self) = @_;
  join('/',($self->destination_directory, 'alleles',$self->gene_name.'.tfa'));
}

sub _build__output_profile_filename
{
  my ($self) = @_;
  join('/',($self->destination_directory, 'profiles',$self->_sub_directory.'.txt'));
}

sub _build_destination_directory
{
  my ($self) = @_;
  my $destination_directory = join('/',($self->base_directory,$self->_sub_directory));
  make_path($destination_directory);
  make_path(join('/',($destination_directory,'alleles')));
  make_path(join('/',($destination_directory,'profiles')));
  return $destination_directory;
}

sub _sub_directory
{
  my ($self) = @_;
  my $combined_name = join('_',($self->species));
  $combined_name =~ s!\.$!!gi;
  $combined_name =~ s!\W!_!gi;
  return $combined_name;
}


sub create_mlst_files
{
  my ($self) = @_;
  
  $self->_download_file($self->input_file,$self->destination_directory);
  
  my $fasta_obj     = Bio::SeqIO->new( -file => join('/',($self->destination_directory, $self->_get_filename_from_url($self->input_file))) , -format => 'Fasta');
  my $out_fasta_obj = Bio::SeqIO->new(-file => "+>".$self->_output_allele_filename , -format => 'Fasta');
  
  my @sequence_names;
  my $counter = 1;
  while(my $seq = $fasta_obj->next_seq())
  {
    my $normalised_name = $self->gene_name."-".$counter;
    push(@sequence_names,[$seq->id,$counter]);
    $seq->id($normalised_name);

    $out_fasta_obj->write_seq($seq);
    $counter++;
  }
  
  $self->_create_profile(\@sequence_names);
  return $self;
}

sub _create_profile
{
  my ($self,$sequence_names) = @_;
  open(my $profile, '+>', $self->_output_profile_filename ) or die 'Couldnt open output profile file';

  my $csv_out = Text::CSV->new({binary=>1, always_quote=>1, sep_char=>"\t", eol=>"\n"});
  $csv_out->print($profile,['ST',$self->gene_name]);
  
  
  for my $sequence_type_details (@{$sequence_names})
  {
    $csv_out->print($profile,$sequence_type_details);
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
