Multilocus sequence typing 
-----
This application is for taking MLST sources from multiple locations and consolidating them in one place so that they can be easily used (and kept up to date).
Then you can provide FASTA files and get out sequence types for a given MLST database.
Two spreadsheets are outputted, one contains the allele number for each locus, and the ST (or nearest ST), the other contains the genomic sequence for each allele.  
If more than 1 allele gives 100% identity for a locus, the contaminated flag is set.
Optionally you can output a concatenated sequence in FASTA format, which you can then use with tree building programs.
New, unseen alleles are saved in FASTA format, with 1 per file, for submission to back to MLST databases.

It requires NCBI Blast+ to be installed and for blastn and makeblastdb to be in your PATH.

For any queries, contact path-help@sanger.ac.uk


Example usage
-------------

# Add this environment variable to your ~/.bashrc file - do this once
export MLST_DATABASES=/path/to/where_you_want_to_store_the_databases

# Download the latest copy of the databases (run it once per month)
download_mlst_databases

# Find the sequence types for all fasta files in your current directory
get_sequence_type -s "Clostridium difficile" *.fa