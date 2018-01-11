# Multilocus sequence typing 

Multilocus sequence typing by blast using the schemes from PubMLST.

[![Build Status](https://travis-ci.org/sanger-pathogens/mlst_check.svg?branch=master)](https://travis-ci.org/sanger-pathogens/mlst_check)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/sanger-pathogens/mlst_check/blob/master/GPL-LICENSE)
[![status](http://joss.theoj.org/papers/0b801d23613c9b626c2b6028f8c14056/status.svg)](http://joss.theoj.org/papers/0b801d23613c9b626c2b6028f8c14056)

# Contents
* [Multilocus sequence typing](#multilocus-sequence-typing)
* [Contents](#contents)
  * [Introduction](#introduction)
* [Citation](#citation)
* [Usage](#usage)
* [Input format](#input-format)
* [Outputs](#outputs)
  * [mlst\_results\.allele\.csv](#mlst_resultsallelecsv)
  * [mlst\_results\.genomic\.csv](#mlst_resultsgenomiccsv)
  * [\*unknown\.fa](#unknownfa)
  * [concatenated\_alleles\.fa and concatenated\_alleles\.phylip](#concatenated_allelesfa-and-concatenated_allelesphylip)
* [Method](#method)
* [Installation](#installation)
  * [Docker](#docker)
  * [Debian/Ubuntu](#debianubuntu)
  * [HomeBrew/LinuxBrew](#homebrewlinuxbrew)
* [Reporting bugs and getting support](#reporting-bugs-and-getting-support)
* [Contribute to the software](#contribute-to-the-software)

## Introduction
This application is for taking MLST databases from multiple locations and consolidating them in one place so that they can be easily used (and kept up to date).
Then you can provide FASTA files and get out sequence types (ST) for a given MLST database.
Two spreadsheets are outputted, one contains the allele number for each locus, and the ST (or nearest ST), the other contains the genomic sequence for each allele.  
If more than 1 allele gives 100% identity for a locus, the contaminated flag is set.
Optionally you can output a concatenated sequence in FASTA format, which you can then use with tree building programs.
New, unseen alleles are saved in FASTA format, with 1 per file, for submission to back to MLST databases.

# Citation
```"Multilocus sequence typing by blast from de novo assemblies against PubMLST", Andrew J. Page, Ben Taylor, Jacqueline A. Keane, The Journal of Open Source Software, (2016). doi: http://dx.doi.org/10.21105/joss.00118```

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
The input files must be in [FASTA format](https://en.wikipedia.org/wiki/FASTA_format) and contain nucleotide sequences. These can be full genome sequences, fragmented _de novo_ assemblies or individual genes. If the gene is truncated or split over 2 sequences, it is unlikely to be detected by this algorithm, however MLST genes usually assemble consistently well because they have been carefully chosen by the schemes creators.

# Outputs

## mlst_results.allele.csv
This is a tab separated spreadsheet containing the ST number of each input FASTA file and the corresponding allele numbers for each gene in the scheme. If one of the alleles is not contained in the database, then it will be flagged with 'U' and the 3rd column will describe it as 'Unknown'. If the combination of allele numbers has never been seen before, it will be flagged as 'Novel'. The ST column is populated with the nearest ST found. A whole number indicates an exact match was found for the ST. If it is prepended with a tilda (~) it indicates it is a 'best effort' and the nearest matching ST with the lowest number is used.  Should two diffent alleles for a single gene be found, then the allele numbers will be put into the 'Contamination' column (since there shouldnt be 2 copies of these genes). However some schemes are poorly defined so take it with a pinch of salt.  If there are no matches such as in _sample5_ below, the ST is blank and all alleles are marked with unknown (U).

Isolate | ST  |"New ST" |Contamination     | aroC | dnaN | hemD | hisD | purE | sucA | thrA
------- | --- | --------|------------------|------|------|------|------|------|------|-----
sample1 | ~559| Unknown |                  | 130  | 97   | 25   | 125  | U    | 9    | 101
sample2 | 518 |         |                  | 101  | 41   | 40   | 184  | 76   | 90   | 3
sample3 | 150 |         | purE-422,purE-84 | 130  | 97   | 25   | 125  | 422  | 9    | 101
sample4 | ~150| Novel   |                  | 130  | 95   | 25   | 125  | 422  | 9    | 101
sample5 |     |	Unknown |                  | U    | U    | U    | U    | U    | U    | U 

## mlst_results.genomic.csv
This spreadsheet is similar to the mlst_results.allele.csv spreadsheet, however it gives the full sequences of each allele instead of the allele number.

## *unknown.fa
You can choose to output any new alleles (-c) which are not contained in the MLST database. These can then be used to feedback to the curators maintaining the MLST databases, where they can be assigned allele numbers and profiles.

## concatenated_alleles.fa and concatenated_alleles.phylip
You can choose to output a multiple FASTA/Phylip alignment of all of the MLST genes concatenated together, where each sample is represented by a single sequence. This file can then be used as input to a phylogenetic tree building application (such as RAxML or FastTree) to create a phylogenetic tree (dendrogram).

# Method
The user can decide to use a specific MLST scheme or search all of them. The first step is to generate a blastn database using makeblastdb from the alleles.  The input sequences are then blasted against the database using blastn.  If there is a 100% match to the full length of an allele, the corresponding allele number is noted. If there is a partial match to an allele, the best hit is chosen, where it has the highest number of matching bases and the highest percentage identity. This nearest allele number is noted and it is flagged as 'Unknown'.  If there is contamination, and more than 1 allele for a single gene is 100% present, the corresponding allele numbers are presented in the contamination column. The first allele in the blast results is used for the gene.  The profile for the MLST scheme links the combination of allele numbers for each gene to an ST number.  This number is presented if there is an exact match.  If one or more of the alleles is _Unknown_, the nearest ST with the lowest integer number is used. Where the combination of allele numbers is unique, the ST is marked as _Novel_ and the ST with the closest number of matches and the lowest integer is presented and indicated with a tilda (~).

# Installation
Instructions are given for installing the software via Docker (can be run on all operating systems),for Debian/Ubuntu distributions and HomeBrew/LinuxBrew.

## Docker
We have a docker container which is setup and ready to go. It includes a snapshot of the MLST databases from the day it was built.  To install it:

```
docker pull sangerpathogens/mlst_check
```

We have included some example data in the container, which can be run using this command:
```
docker run --rm -it -v /home/ubuntu/data:/data sangerpathogens/mlst_check get_sequence_type -s 'Salmonella enterica' /example/sample1.fa /example/sample2.fa /example/sample3.fa
```
Your results will then be in the /home/ubuntu/data directory (or whatever you have called it). 


To use the command with your own data place your FASTA files in /home/ubuntu/data (or substituting in your directories):
```
docker run --rm -it -v /home/ubuntu/data:/data sangerpathogens/mlst_check get_sequence_type -s 'Salmonella enterica' my_sample.fa
```
Your results will then be in the /home/ubuntu/data directory as previous. 

## Debian/Ubuntu
If you run Debian or Ubuntu it should be straightforward to install the software. These instructions assume you have root access. Run:

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

## HomeBrew/LinuxBrew
If you run OSX, a non-Debian Linux or you do not have root access on your machine, you can use HomeBrew/LinuxBrew to install the dependancies.  First of all install [Homebrew](http://brew.sh/) (OSX) or [LinuxBrew](http://linuxbrew.sh/) (Linux).

```
brew tap homebrew/science
brew install cpanminus blast
```

Assuming you have setup perl modules to install in your local directory (~/perl5 in this case), this command will install this software and all its Perl dependancies:
```
cpanm --local-lib=~/perl5 -f Bio::MLST::Check
```
The process from this point is the same as installing with Debian.
Set a directory where you would like to store the MLST databases.
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

# Reporting bugs and getting support
For any queries, please file an [Issue on GitHub](https://github.com/sanger-pathogens/mlst_check/issues) or failing that contact path-help@sanger.ac.uk

# Contribute to the software
If you wish to fix a bug or add new features to the software we welcome Pull Requests. Please fork the repo, make the change, then submit a Pull Request with details about what the change is and what it fixes/adds.
