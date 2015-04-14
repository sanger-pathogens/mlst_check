package Bio::MLST::CheckMultipleSpecies;

# ABSTRACT: High throughput multilocus sequence typing (MLST) checking against several MLST databases.

=head1 SYNOPSIS

This is a wrapper for the Bio::MLST::Check module allowing MLST checking against several databases.

The Bio::MLST::Check options to output a concatenated fasta file of allele matches or to output a 
phylip alignment file are not supported as the loci for sequence typing will vary between species.
Including these options will give an error message requesting that the user refine their search.

   use Bio::MLST::CheckMultipleSpecies;
   
   my @fasta_files  = ('isolate_one.fa', 'isolate_two.fa');
   my @species_list = ('Clostridium diff', 'Streptococcus');
   
   my $mlst = Bio::MLST::CheckMultipleSpecies->new( species               => \@species_list,
                                                    raw_input_fasta_files => \@fasta_files,
                                                    spreadsheet_basename  => $spreadsheet_basename,
                                                    output_directory      => $output_directory,
                                                    base_directory        => $base_directory,
                                                    makeblastdb_exec      => $makeblastdb_exec,
                                                    blastn_exec           => $blastn_exec,
                                                    parallel_processes    => $parallel_processes,
                                                    verbose               => 0,);
   $multiple_species->create_result_files;
   

=method create_result_files

Creates a spreadsheet of results.

=head1 SEE ALSO

=for :list
* L<Bio::MLST::Check>

=cut


use Moose;
use Bio::MLST::Check;
use Bio::MLST::Databases;
use Parallel::ForkManager;
use File::Temp;
use Cwd;
use Text::CSV;

has 'species'               => ( is => 'ro', isa => 'ArrayRef', required => 1 ); # empty array searches against all databases
has 'base_directory'        => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'parallel_processes'    => ( is => 'ro', isa => 'Int',      default  => 1 ); # max parallel processes
has 'verbose'               => ( is => 'rw', isa => 'Bool',     default  => 0 ); # output search progress and number of matches
has 'report_all_mlst_db'    => ( is => 'rw', isa => 'Bool',     default  => 0 ); # report all mlst databases searched
has 'report_lowest_st'      => ( is => 'rw', isa => 'Bool',     default  => 0 );

has 'raw_input_fasta_files' => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'makeblastdb_exec'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'blastn_exec'           => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'output_directory'      => ( is => 'ro', isa => 'Str',      required => 1 ); 
has 'spreadsheet_basename'  => ( is => 'ro', isa => 'Str',      default  => 'mlst_results' ); 
has 'output_fasta_files'    => ( is => 'ro', isa => 'Bool',     default  => 0 ); # output of fasta not supported
has 'output_phylip_files'   => ( is => 'ro', isa => 'Bool',     default  => 0 ); # output of phylip not supported
has 'show_contamination_instead_of_alt_matches' => ( is => 'ro', isa => 'Bool',   default => 1 ); 

has '_species_list'         => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1 );
has '_working_directory'    => ( is => 'ro', isa => 'File::Temp::Dir', default => sub { File::Temp->newdir(DIR => getcwd, CLEANUP => 1); });

sub _build__species_list
{
    my($self) = @_;
    my @species_list = @{$self->species};

    # if no species supplied then run vs all species
    unless(@species_list)
    {
        my $mlst_databases = Bio::MLST::Databases->new(
            base_directory => $self->base_directory,
            );
        @species_list = @{$mlst_databases->database_names};
    }

    @species_list = sort { $a cmp $b } @species_list;

    return \@species_list;
}

sub _check_input_files_exist
{
    my($self) = @_;

    my $check = Bio::MLST::Check->new( raw_input_fasta_files => $self->raw_input_fasta_files,
                                       species               => '',
                                       base_directory        => '',
                                       makeblastdb_exec      => '',
                                       blastn_exec           => '',
                                       output_directory      => '' );

    return $check->input_fasta_files_exist;
}

# print error message if phylip or fasta files requested
sub _check_fasta_phylip_options
{
    my($self) = @_;

    return 1 unless ($self->output_fasta_files || $self->output_phylip_files);

    print qq[
 The --output_fasta_files and --output_phylip_files options cannot be used when searching
 against more than one MLST database as the alleles searched will differ between species.

 To output fasta and phylip files, please search against a single MLST database.\n\n];
    return 0;
}

sub _run_mlst_for_species_list
{
    my ($self) = @_;

    # set parallel processes - if more species than processes then search input files in parallel.
    my $parallel_process_total   = $self->parallel_processes;
    my $parallel_process_species = @{$self->_species_list} < $self->parallel_processes ? @{$self->_species_list} : $self->parallel_processes;
    my $parallel_process_fa_file = int($self->parallel_processes/@{$self->_species_list}) ? int($self->parallel_processes/@{$self->_species_list}) : 1;

    # Run for each species - output to csv files named 0001,0002,etc.
    my $pm = new Parallel::ForkManager($self->parallel_processes);
    for(my $i=1; $i <= @{$self->_species_list}; $i++)
    {
        $pm->start and next; # fork here

        my $spreadsheet_basename = sprintf "%04i",$i;
        my $species_name = $self->_species_list->[$i-1];
        print qq[ Searching $species_name...\n] if $self->verbose;

        my $multiple_fastas = Bio::MLST::Check->new(
            species               => $species_name,
            base_directory        => $self->base_directory,
            raw_input_fasta_files => $self->raw_input_fasta_files,
            makeblastdb_exec      => $self->makeblastdb_exec,
            blastn_exec           => $self->blastn_exec,
            output_directory      => $self->_working_directory->dirname(),
            spreadsheet_basename  => $spreadsheet_basename,
            parallel_processes    => $parallel_process_fa_file,
            output_fasta_files    => $self->output_fasta_files,
            output_phylip_files   => $self->output_phylip_files,
            show_contamination_instead_of_alt_matches => $self->show_contamination_instead_of_alt_matches,
            report_lowest_st      => $self->report_lowest_st
            );
        $multiple_fastas->create_result_files;

        $pm->finish;
    }
    $pm->wait_all_children;
    print qq[ Finished searching\n] if $self->verbose;

    return 1;
}

sub _concatenate_result_files
{
    my ($self) = @_;

    for my $file_type ('allele','genomic') 
    {
        # open output filehandle and csv 
        my $result_file  = $self->output_directory.'/'.$self->spreadsheet_basename.'.'.$file_type.'.csv';
        open(my $fh_out,  '>'.$result_file)  or die "Can't open file: $result_file $!\n";
        my $csv_out = Text::CSV->new({binary=>1, sep_char=>"\t", always_quote=>1, eol=>"\r\n"});
        
        # process temp result files 0001,0002,etc.
        my $previous_positive_result = 0;
        my $results_found_flag       = 0;
        for(my $i=1; $i <= @{$self->_species_list}; $i++)
        {
            # species and file naming
            my $species_name = $self->_species_list->[$i-1];
            $species_name =~ s/_/ /g;
            my $working_dir  = $self->_working_directory->dirname();
            my $spreadsheet_basename = sprintf "%04i",$i;
            my $result_file_temp  = $working_dir.'/'.$spreadsheet_basename.'.'.$file_type.'.csv';

            # input csv and filehandle
            my $csv_in = Text::CSV->new({binary=>1, sep_char=>"\t", eol=>"\r\n"});
            my $fh_in;
        
            # results rows
            my @header_row    = (); 
            my @isolate_rows  = ();
            my @positive_rows = ();

            # parse temp results file
            open($fh_in, $result_file_temp);
            while(my $line = <$fh_in>)
            {
                $csv_in->parse($line);
                my @row = $csv_in->fields();
                next unless @row;

                if($row[0] eq 'Isolate' && $row[1] eq 'ST')
                {
                    @header_row = @row;
                    next;
                }
            
                push(@isolate_rows,  \@row);
                # filter results
                for(my $i=4; $i<@row; $i++)
                {
                    if($row[$i] ne 'U')
                    {
                        push(@positive_rows, \@row);
                        last;
                    }
                }
            }   
            close $fh_in;

            # Sort results by file name
            @isolate_rows  = sort{ $a->[0] cmp $b->[0] } @isolate_rows;
            @positive_rows = sort{ $a->[0] cmp $b->[0] } @positive_rows;

            # output to final file
            if($self->report_all_mlst_db)
            {
                $csv_out->print($fh_out,['']) if((@positive_rows || $previous_positive_result) && $i > 1); # blank row
                $csv_out->print($fh_out,[$species_name,'matched '.scalar(@positive_rows).' of '.scalar(@isolate_rows).' files']);
            }
            elsif(@positive_rows) 
            {
                $csv_out->print($fh_out,['']) if($previous_positive_result && $i > 1); # blank row
                $csv_out->print($fh_out,[$species_name,'matched '.scalar(@positive_rows).' of '.scalar(@isolate_rows).' files']);
            }

            if(@positive_rows)
            {
                $csv_out->print($fh_out,\@header_row);
                for my $row (@positive_rows)
                {
                    $csv_out->print($fh_out,$row);
                }
            }
            $previous_positive_result = scalar(@positive_rows) ? 1:0;
            $results_found_flag = 1 if scalar(@positive_rows);

            printf " %-40s %d/%d\n",$species_name,scalar(@positive_rows),scalar(@isolate_rows) if ($self->verbose && $file_type eq 'allele'); # verbose
        }

        # no matches found
        if(!$self->report_all_mlst_db && !$results_found_flag)
        {
            $csv_out->print($fh_out,['No matches found']);
        }

        close $fh_out;
    }

    return 1;
}

sub create_result_files
{
    my($self) = @_;

    exit unless $self->_check_input_files_exist;
    exit unless $self->_check_fasta_phylip_options;
    $self->_run_mlst_for_species_list();
    $self->_concatenate_result_files();

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
