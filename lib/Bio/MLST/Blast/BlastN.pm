package Bio::MLST::Blast::BlastN;
# ABSTRACT: Wrapper around NCBI BlastN

=head1 SYNOPSIS

Wrapper around NCBI BlastN. Run NCBI blast and find the top hit.

   use Bio::MLST::Blast::BlastN;
   
   my $blast_database= Bio::MLST::Blast::BlastN->new(
     blast_database => 'output_contigs',
     query_file     => 'alleles/adk.tfa',
     word_size      => 500,
     exec           => 'blastn'
   );
   $blast_database->top_hit();

=method top_hit

Returns a hash containing details about the top blast result.

The attributes returned in the hash are:
  allele_name
  percentage_identity
  source_name
  source_start
  source_end
  reverse
  contamination

=head1 SEE ALSO

=for :list
* L<Bio::MLST::Blast::Database>

=cut

use Moose;
use Bio::MLST::Types;
use List::Util qw(reduce max);

# input variables
has 'blast_database'     => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'query_file'         => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'word_sizes'         => ( is => 'ro', isa => 'HashRef', required => 1 ); 
has 'exec'               => ( is => 'ro', isa => 'Bio::MLST::Executable', default  => 'blastn' ); 
has 'perc_identity'      => ( is => 'ro', isa => 'Int', default  => 95 );

# Generated
has 'top_hit'           => ( is => 'ro', isa => 'Maybe[HashRef]', lazy => 1,  builder => '_build_top_hit' ); 

sub _build_hit
{
  my($self, $line) = @_;
  chomp($line);
  my @row = split(/\t/,$line);
  my ($start, $end) = ($row[8], $row[9]);
  ($start, $end, my $reverse) = $start <= $end ? ($start, $end, 0) : ($end, $start, 1);
  return {
    'allele_name' => $row[0],
    'source_name' => $row[1],
    'percentage_identity' => $row[2],
    'alignment_length' => $row[3],
    'source_start' => $start,
    'source_end' => $end,
    'reverse' => $reverse,
  };
}

sub _build_hits
{
  my ($self, $blast_output_fh) = @_;
  my @hits;
  while(<$blast_output_fh>)
  {
    push @hits, $self->_build_hit($_);
  }
  return \@hits;
}

sub _filter_by_alignment_length
{
  ###
  # For each allele there is a minimum length of sequence it must be aligned
  # against before it can be considered a match.
  ###
  my ($self, $hits, $word_sizes) = @_;
  my @long_hits = grep { $_->{'alignment_length'} >= $word_sizes->{$_->{'allele_name'}} } @$hits;
  return \@long_hits;
}

sub _filter_best_hits
{
  my($self, $hits, $tollerance) = @_;
  $tollerance = defined($tollerance) ? $tollerance : 2.0;
  my @percentages = map { $_->{'percentage_identity'} } @$hits;
  my $top_percentage = max @percentages;
  my @top_hits = grep { $_->{'percentage_identity'} >= $top_percentage - $tollerance } @$hits;
  return \@top_hits;
}

sub _group_overlapping_hits
{
  ###
  # Hits can overlap, this groups hits which overlap and returns a reference to
  # an array of references to these groups.
  ###
  my($self, $hits) = @_;
  my @bins = ();
  foreach my $hit (@$hits)
  {
    my $found_a_bin = 0;
    foreach my $bin (@bins)
    {
      # check if hit is in bin
      if (($hit->{'source_start'} >= $bin->{'start'}) and ($hit->{'source_end'} <= $bin->{'end'}))
      {
        push $bin->{'hits'}, $hit;
        $found_a_bin = 1;
        last;
      }
      # check if bin is in hit
      elsif (($hit->{'source_start'} <= $bin->{'start'}) and ($hit->{'source_end'} >= $bin->{'end'}))
      {
        push $bin->{'hits'}, $hit;
        $bin->{'start'} = $hit->{'source_start'};
        $bin->{'end'} = $hit->{'source_end'};
        $found_a_bin = 1;
        last;
      }
    }
    # If we've not found a bin for this hit, make a new one
    if (!$found_a_bin)
    {
      my $new_bin = {
        'start' => $hit->{'source_start'},
        'end' => $hit->{'source_end'},
        'hits' => [$hit]
      };
      push @bins, $new_bin;
    }
  }
  my @groups = map { $_->{hits} } @bins;
  return \@groups;
}

sub _best_hit_in_group
{
  ###
  # The best hit must be the longest.  If there is more than one hit with the
  # maximum length, return the one with the best percentage_identity
  ###
  my($self, $hits) = @_;
  my @lengths = map { $_->{'source_end'} - $_->{'source_start'} + 1 } @$hits;
  my $max_length = max @lengths;
  my @longest_hits = grep { $_->{'source_end'} - $_->{'source_start'} + 1 >= $max_length } @$hits;
  my $best_hit = reduce { $a->{'percentage_identity'} > $b->{'percentage_identity'} ? $a : $b } @longest_hits;
  return $best_hit;
}

sub _highlight_imperfect_matches
{
  ###
  # If a match isn't 100% add a * to the allele_name to make this clear
  ###
  my($self, $hits) = @_;
  my @output = map {
    my $hit = { %$_ }; # make a shallow copy of the original hit
    if ($hit->{'percentage_identity'} < 100.0) {
      $hit->{'allele_name'} = "$hit->{'allele_name'}*";
    }
    $hit;
  } @$hits;

  return \@output;
}

sub _blastn_cmd
{
  my($self) = @_;
  my $word_size = int(100/(100 - $self->perc_identity ));
  $word_size = 11 if($word_size < 11);
  
  join(' ',($self->exec, '-task blastn', '-query', $self->query_file, '-db', $self->blast_database, '-outfmt 6', '-word_size', $word_size , '-perc_identity', $self->perc_identity ));
}

sub _build_top_hit
{
  my($self) = @_;
  open(my $copy_stderr_fh, ">&STDERR"); open(STDERR, '>/dev/null'); # Redirect STDERR
  open( my $blast_output_fh, '-|',$self->_blastn_cmd);
  close(STDERR); open(STDERR, ">&", $copy_stderr_fh); # Restore STDERR
  my %top_hit;
  my $top_hit_percentage_identity = 0;
  my %contamination_check;

  while(<$blast_output_fh>)
  {
    chomp;
    my $line = $_;
    my @blast_raw_results = split(/\t/,$line);
    next unless($blast_raw_results[3] >= $self->word_sizes->{$blast_raw_results[0]});
    my $percentage_identity = $blast_raw_results[2];

    if(@blast_raw_results  > 8 && $percentage_identity >= $top_hit_percentage_identity)
    {
      my $start  = $blast_raw_results[8];
      my $end  = $blast_raw_results[9];
      ($start, $end, my $reverse) = $start <= $end ? ($start, $end, 0) : ($end, $start, 1);

      my $allele_name = $blast_raw_results[0];

      if ($top_hit_percentage_identity == 100)
      {
        # We've already found one 100% match, check this isn't a truncation
        # FIXME: Favors shorter alleles if there are SNPs:
        # If allele_2 is a truncation of allele_1 and allele_1 has a SNP in the truncated region
        # only allele_2 is matched.  This is true more generally that contaminations are not
        # picked up if one of them has a SNP.
        if ($start >= $top_hit{source_start} && $end <= $top_hit{source_end}) {
          # This is a truncation of the top_hit
          # Move onto the next match without updating the top_hit or contamination
          next;
        } elsif ($start <= $top_hit{source_start} && $end >= $top_hit{source_end}) {
          # The top_hit is a truncation of this
          # Remove top_hit from hash of contaminants
          delete $contamination_check{$top_hit{allele_name}};
          $contamination_check{$allele_name} = $percentage_identity;
          # Update the top hit
        } else {
          # There does appear to be some contamination
          # Update the list of contaminants
          $contamination_check{$allele_name} = $percentage_identity;
          # Update the top hit
          # FIXME: Always picks the last even if it is a shorter match, which it probably is because
          # blastn prioritises its output (I think).
        }
      } elsif ($percentage_identity == 100) {
        # This is the first 100% match
        # Add this to the list of contaminants
        $contamination_check{$allele_name} = $percentage_identity;
      }

      $top_hit{allele_name} = $allele_name;
      $top_hit{percentage_identity} = int($percentage_identity); # NB rounded down to int
      $top_hit_percentage_identity = $percentage_identity; # NB not rounded down
      $top_hit{source_name} = $blast_raw_results[1];
      $top_hit{source_start} = $start;
      $top_hit{source_end} = $end;
      $top_hit{reverse} = $reverse;
    }
  }
  
  if((keys %contamination_check) >= 2)
  {
    my @found_alleles = keys(%contamination_check);
    $top_hit{contamination} = \@found_alleles;
  }
  
  return \%top_hit;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
