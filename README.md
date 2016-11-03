# Multilocus sequence typing 

[![Build Status](https://travis-ci.org/sanger-pathogens/mlst_check.svg?branch=master)](https://travis-ci.org/sanger-pathogens/mlst_check)

This application is for taking MLST databases from multiple locations and consolidating them in one place so that they can be easily used (and kept up to date).
Then you can provide FASTA files and get out sequence types (ST) for a given MLST database.
Two spreadsheets are outputted, one contains the allele number for each locus, and the ST (or nearest ST), the other contains the genomic sequence for each allele.  
If more than 1 allele gives 100% identity for a locus, the contaminated flag is set.
Optionally you can output a concatenated sequence in FASTA format, which you can then use with tree building programs.
New, unseen alleles are saved in FASTA format, with 1 per file, for submission to back to MLST databases.

For any queries, contact path-help@sanger.ac.uk

# Usage
The MLST databases must be downloaded first. This is something you would only do every now and again. You need to set the $MLST_DATABASES environment variable first to a location where you want to save your databases. If you use Docker, you can skip this step as the databases are bundled with the container.
```
Usage: download_mlst_databases [options]
   -c STR Config file containing details of MLST databases from pubMLST
   -b STR Directory where MLST databases are stored [$MLST_DATABASES]
   -h     Print this message and exit
   -v     Print version number and exit
```

The get_sequence_type script allows you to calculate the ST of a FASTA file against one or more database. If you dont provide the '-s' option, then every database will be searched.  If you wish to build a phylogenetic tree of then use the '-c' or '-y' options to get a single aligned FASTA/Phylip file.
```
Usage: The get_sequence_type [options] *.fasta

   -s STR Species of MLST database (0 or more comma separated)
   -d INT Number of threads [1]
   -c     Output a FASTA file of concatenated alleles and unknown sequences 
   -y     Output a phylip file of concatenated alleles and unknown sequences
   -o STR Output directory [.]
   -a     Print out all available MLST databases and exit
   -h     Print this message and exit
   -v     Print version number and exit
```


# Input format
The input files must be in FASTA format.

# Outputs

## mlst_results.allele.csv
This is a tab separated spreadsheet containing the ST number of each input FASTA file and the corresponding allele numbers for each gene in the scheme. If one of the alleles is not contained in the database, then it will be flagged with 'U' and the 3rd column will describe it as 'Unknown'. If the combination of allele numbers has never been seen before, it will be flagged as 'Novel'. The ST column is populated with the nearest ST found. Should two diffent alleles for a single gene be found, then the allele numbers will be put into the 'Contamination' column (since there shouldnt be 2 copies of these genes). However some schemes are poorly defined so take it with a pinch of salt.

Isolate | ST  |"New ST" |Contamination     | aroC | dnaN | hemD | hisD | purE | sucA | thrA
------- | --- | --------|------------------|------|------|------|------|------|------|-----
sample1 | ~559| Unknown |                  | 130  | 97   | 25   | 125  | U    | 9    | 101
sample2 | 518 |         |                  | 101  | 41   | 40   | 184  | 76   | 90   | 3
sample3 | 150 |         | purE-422,purE-84 | 130  | 97   | 25   | 125  | 422  | 9    | 101
sample4 | ~150| Novel   |                  | 130  | 95   | 25   | 125  | 422  | 9    | 101

##mlst_results.genomic.csv
This spreadsheet is similar to the mlst_results.allele.csv spreadsheet, however it gives the full sequences of each allele instead of the allele number.


#Installation
Instructions are given for installing the software via Docker (can be run on all operating systems) and for Debian/Ubuntu distributions.

##Docker
We have a docker container which is setup and ready to go. It includes a snapshot of the MLST databases from the day it was built.  To install it:

```
docker pull sangerpathogens/mlst_check
```

To use it you would use a command such as this (substituting in your directories), where your FASTA files are assumed to be stored in /home/ubuntu/data:
```
docker run --rm -it -v /home/ubuntu/data:/data sangerpathogens/mlst_check get_sequence_type -s "Clostridium difficile" /data/*.fa
```

Your results will then be in the /home/ubuntu/data directory (or whatever you have called it).


##Debian/Ubuntu
If you run Debian or Ubuntu it should be straightforward to install the software. Run:

```
apt-get update -qq
apt-get install -y ncbi-blast+ cpanminus gcc autoconf make libxml2-dev zlib1g zlib1g-dev libmodule-install-perl
cpanm -f Bio::MLST::Check
```

Then you need to set a directory where you would like to store the MLST databases.
```
export MLST_DATABASES=/path/to/where_you_want_to_store_the_databases
```

Download the latest copy of the databases (run it once per month)
```
download_mlst_databases
```
Now you can use the script. For example,find the sequence types for all fasta files in your current directory:
```
get_sequence_type -s "Clostridium difficile" *.fa
```

