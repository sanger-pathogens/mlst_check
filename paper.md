---
title: 'Multilocus sequence typing by blast from de novo assemblies against PubMLST'
tags:
  - bioinformatics
  - MLST
  - sequence typing
authors:
 - name: Andrew J. Page
   orcid: 0000-0001-6919-6062
   affiliation: Pathogen Informatics, Wellcome Trust Sanger Institute
 - name: Ben Taylor
   affiliation: Pathogen Informatics, Wellcome Trust Sanger Institute
 - name: Jacqueline A. Keane
   orcid: 0000-0002-2021-1863
   affiliation: Pathogen Informatics, Wellcome Trust Sanger Institute
  
date: 3 Nov 2016
bibliography: paper.bib
---

# Summary
Multilocus sequence typing is a standard method for categorising genomes [@Maiden1998] based on variation in a small set of conserved house keeping genes. It allows for rapid identification of genomes into high level categories and is extrememly useful for epidemilogical investigations [@Urwin2003] making it a key tool for public health reference laboratories. Whilst MLST is more commonly asssosiated with classical sequencing methods, it is possible to extract the same information from Next Generation Sequencing data, in particular from de novo assemblies which are generated routinely for bacterial sequencing data [@PAGE2016]. 

We provide a scalable command line tool, MLSTcheck, which can take multiple de novo assemblies and output detailed information about the sequence type of the sample. It can search one or more databases at once, is parallelisable, fast and robust. When a sample contains more than one allele, it flags the contaminent since there should only be 1 copy of a house keeping gene in a well designed MLST scheme. A multiple FASTA alignment of the concatentated MLST genes is optionally outputted, allowing for the creation of phylogenetic trees. This allows for rapid epidemilogical outbreak investigations.  Whilst other software applications can perform similar functions [Seeman2016; Jolley2010], this application follows more rigourous software engineering principles, including automated testing, continous integration, object orientated code, and is installable via CPAN (a Perl package manager).  In a large diverse set of 6814 publicly accessible draft assemblies, MLSTcheck was able to assign a sequence type in 99.6% of cases [@PAGE2016].

# References