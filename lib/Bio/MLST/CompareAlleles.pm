package Bio::MLST::CompareAlleles;

# ABSTRACT: Get a list of matching alleles between the sequence and database

=head1 SYNOPSIS

Take in an assembly file in Fasta format, and a list of allele files (in multifasta format) and return a list of the alleles and IDs.

   use Bio::MLST::CompareAlleles;
   
   my $compare_alleles = Bio::MLST::CompareAlleles->new(
   
     sequence_filename => 'contigs.fa',
     allele_filenames => ['abc.tfa','efg.tfa']
   );
   $compare_alleles->found_sequence_names;
   $compare_alleles->found_non_matching_sequence_names
   $compare_alleles->matching_sequences;
   $compare_alleles->non_matching_sequences

=method found_sequence_names

Return a list of the sequence names which match.

=method found_non_matching_sequence_names

Return a list of the sequence names which dont match.

=method matching_sequences

Return a Hash containing the sequnces that match.

=method non_matching_sequences

Return a Hash containing the sequnces that dont match.

=method contamination

Flag which is set if more than one 100% match is found for a single locus.

=method new_st

Flag which is set if the results contain a novel combination of sequences or a new sequence.

=head1 SEE ALSO

=for :list
* L<Bio::MLST::Check>

=cut

use Data::Dumper;

use Moose;
use File::Basename;
use Bio::SeqIO;
use Bio::Perl;
use Bio::MLST::Blast::Database;
use Bio::MLST::Blast::BlastN;
use Bio::MLST::Types;
use Bio::MLST::SequenceType;

has 'sequence_filename'      => ( is => 'ro', isa => 'Bio::MLST::File',      required => 1 );
has 'allele_filenames'       => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'makeblastdb_exec'       => ( is => 'ro', isa => 'Str',      default  => 'makeblastdb' );
has 'blastn_exec'            => ( is => 'ro', isa => 'Str',      default  => 'blastn' );

has '_sequence_handle'       => ( is => 'ro', isa => 'Bio::SeqIO::fasta',     lazy => 1,  builder => '_build__sequence_handle');
has '_blast_db_location_obj' => ( is => 'ro', isa => 'Bio::MLST::Blast::Database', lazy => 1,  builder => '_build__blast_db_location_obj');
has '_blast_db_location'     => ( is => 'ro', isa => 'Str',                   lazy => 1,  builder => '_build__blast_db_location');

has 'matching_sequences'     => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_matching_sequences' );
has 'non_matching_sequences' => ( is => 'rw', isa => 'HashRef', default => sub {{}});
has 'contamination'          => ( is => 'rw', isa => 'Bool',    default => 0);
has 'contamination_alleles'  => ( is => 'rw', isa => 'Maybe[Str]' );
has 'contamination_sequence_names' => ( is => 'rw', isa => 'Maybe[ArrayRef]' );
has 'new_st'                 => ( is => 'rw', isa => 'Bool',    default => 0);
has '_absent_loci'           => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build__absent_loci' );
has 'profiles_filename'     => ( is => 'ro', isa => 'Bio::MLST::File',        required => 1 ); 

sub _build__blast_db_location
{
  my ($self) = @_;
  return $self->_blast_db_location_obj->location();
}

sub _build__blast_db_location_obj
{
  my ($self) = @_;
  return Bio::MLST::Blast::Database->new(fasta_file => $self->sequence_filename, exec => $self->makeblastdb_exec);
}


sub _build__sequence_handle
{
  my ($self) = @_;
  return Bio::SeqIO->new( -file => $self->sequence_filename , -format => 'Fasta');
}

sub sequence_filename_root
{
  my ($self) = @_;
  $self->_get_base_filename($self->sequence_filename);
}

sub found_sequence_names
{
  my ($self) = @_;
  my @sequence_names = sort(keys %{$self->matching_sequences});
  return \@sequence_names;
}

sub found_non_matching_sequence_names
{
  my ($self) = @_;
  my @sequence_names = sort(keys %{$self->non_matching_sequences});
  return \@sequence_names;
}


sub _word_sizes_for_given_allele_file
{
  my ($self,$filename) = @_;
  my %seq_lens;
  my $seqio = Bio::SeqIO->new( -file => $filename , -format => 'Fasta');
  while( my $seq = $seqio->next_seq() ){
    $seq_lens{$seq->primary_id} = $seq->length;
  }
  return \%seq_lens;
}

sub _get_word_size_from_blast_hit {
  my ( $self, $word_sizes, $blast_hit, $allele_filename ) = @_;

  # return len of top blast hit allele, otherwise return len of first seq in allele file
  my ($word_size, $first_seq);
  if( defined $blast_hit->{allele_name} ){
    $word_size = $word_sizes->{$blast_hit->{allele_name}};
  }
  else{
    my $seqio = Bio::SeqIO->new( -file => $allele_filename, -format => 'Fasta' );
    $word_size = $seqio->next_seq->length;
  }

  # unless ( defined $word_size ) {
  #   print "WORD SIZES: ";
  #   print Dumper $word_sizes;
  #   print "BLAST ALLELE: " . $blast_hit->{allele_name} . "\n";
  #   print "FIRST SEQ: " . $first_seq . "\n";
  #   print "WORD SIZE: $word_size\n";
  # }

  return $word_size;
}

sub _build_matching_sequences
{
  my ($self) = @_;
  my %matching_sequence_names;
  my %non_matching_sequence_names;
  my %missing_locus_names;
  
  for my $allele_filename (@{$self->allele_filenames})
  {
    my $word_sizes = $self->_word_sizes_for_given_allele_file($allele_filename);
    my $blast_results = Bio::MLST::Blast::BlastN->new(
      blast_database => $self->_blast_db_location,
      query_file     => $allele_filename,
      word_sizes     => $word_sizes,
      exec           => $self->blastn_exec
    );
    my %top_blast_hit = %{$blast_results->top_hit()};
   
    # possible missing locus
    if(! %top_blast_hit)
    {
      my %absent_loci_type = %{$self->_absent_loci};
      my $allele = $self->_get_base_filename($allele_filename);
      $missing_locus_names{$allele} = $absent_loci_type{$allele} if exists $absent_loci_type{$allele};
    }

    my $word_size = $self->_get_word_size_from_blast_hit($word_sizes, \%top_blast_hit, $allele_filename);

    # unknown allele
    if(! %top_blast_hit)
    {
      $non_matching_sequence_names{$self->_get_base_filename($allele_filename)} = $self->_pad_out_sequence("", $word_size);
      next;
    }
    
    # more than 1 allele has 100% match
    if(defined($top_blast_hit{contamination}))
    {
      $self->contamination(1);
      my $contamination_alleles = join( ',', sort @{ $top_blast_hit{contamination} } );
      $self->contamination_alleles( $contamination_alleles );
      $self->_translate_contamination_names_into_sequence_types($top_blast_hit{contamination},$top_blast_hit{allele_name});
    }
    
    $top_blast_hit{allele_name} =~ s![-_]+!-!g;
    
    if($top_blast_hit{percentage_identity} == 100 )
    {
      $matching_sequence_names{$top_blast_hit{allele_name}} = $self->_get_blast_hit_sequence($top_blast_hit{source_name}, $top_blast_hit{source_start},$top_blast_hit{source_end},$word_size,$top_blast_hit{reverse});
    }
    else
    {
      $non_matching_sequence_names{$top_blast_hit{allele_name}} = $self->_get_blast_hit_sequence($top_blast_hit{source_name}, $top_blast_hit{source_start},$top_blast_hit{source_end},$word_size,$top_blast_hit{reverse});
      $self->new_st(1);
    }
  }

  # deal with missing loci
  if(%matching_sequence_names && %missing_locus_names)
  {
    for my $allele (keys %missing_locus_names)
    {
      delete $non_matching_sequence_names{$allele};
      $matching_sequence_names{$allele.'-'.$missing_locus_names{$allele}} = '';
    }
  }

  # set new ST flag
  $self->new_st(1) if %non_matching_sequence_names;

  $self->non_matching_sequences(\%non_matching_sequence_names);
  return \%matching_sequence_names;
}

sub _translate_contamination_names_into_sequence_types
{
  my ($self, $contamination_names, $main_allele_name) = @_;
  my @contamination_sequence_types;
  
  for my $allele_number (@{ $contamination_names})
  {
    next if($main_allele_name eq $allele_number);
    my $st = Bio::MLST::SequenceType->new(
      profiles_filename => $self->profiles_filename,
      sequence_names => [$allele_number]
    );
    
    if(defined($st->sequence_type()) )
    {
      push(@contamination_sequence_types, $st->sequence_type());
    }
  }
  
  $self->contamination_sequence_names(\@contamination_sequence_types);
}


sub _get_blast_hit_sequence
{
   my ($self, $contig_name, $start, $end, $word_size, $reverse_complement) = @_;
   seek($self->_sequence_handle->_fh, 0,0);
   while( my $input_sequence_obj = $self->_sequence_handle->next_seq() ) 
   {
     next if( $input_sequence_obj->id ne $contig_name);
     my $sequence = $input_sequence_obj->subseq($start, $end);
     if($reverse_complement)
     {
       my $reverse_sequence = revcom( $sequence );
       $sequence = $reverse_sequence->{seq};
     }
     
     $sequence = $self->_pad_out_sequence($sequence, $word_size);
     return $sequence;
   }
   
   return $self->_pad_out_sequence("", $word_size);
}

sub _get_base_filename
{
  my($self, $filename) = @_;
  my $filename_root  = fileparse($filename, qr/\.[^.]*$/);
  return $filename_root;
}

sub _pad_out_sequence
{
  my($self, $input_sequence, $length_of_main_sequence) = @_; 
  return $input_sequence if(length($input_sequence) == $length_of_main_sequence);
  if(length($input_sequence) > $length_of_main_sequence)
  {
    $input_sequence = substr($input_sequence,0,$length_of_main_sequence);
  }
  $input_sequence = "" if($input_sequence eq 'U');
  
  for(my $i=length($input_sequence); $i < $length_of_main_sequence; $i++)
  {
    $input_sequence .= "N";
  }
  return $input_sequence;
}

sub _build__absent_loci
{
  my( $self ) = @_;
  my %absent_loci = ();
    
  for my $allele_file (@{$self->allele_filenames})
  {
    my $seq_io =  Bio::SeqIO->new( -file => $allele_file , -format => 'Fasta');
    while( my $seq = $seq_io->next_seq() )
    {
      if($seq->length == 0)
      {
        my($allele,$type) = split(/[-_]+/,$seq->id(),2);
        $absent_loci{$allele} = $type;
      }
    }
  }

  return \%absent_loci;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
