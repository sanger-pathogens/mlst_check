---
title: 'MLSTcheck: Multilocus sequence typing by blast from assemblies against PubMLST'
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
Multilocus sequence typing is a standard method for classifying genomes[ref mark A]. It allows for rapid identification of organisms into high level cateogries and is extrememly useful for epidemilogical investigations. Its can be performed using any sequencing technology and is heavily used with traditional sequencing methods (capillary sequencing).   This information can also be extracted from Next Generation Sequencing data, in particular from de novo assemblies which are generated routinely for bacterial sequencing data [@PAGE2016]. We provide a scalable command line tool which can take multiple de novo assemblies and output detailed information about the sequence type of the sample. It can search one or more databases at once, is parallelisable, fast and robust. Whilst other software applications exist, some require you to copy and paste individual allele sequences into a web form[xxxxxx], and others do not have automated testing [xxxx].  When a sample contains more than one allele, it flags the contaminent since there should only be 1 copy of a house keeping gene in a well designed MLST scheme. A multiple FASTA alignment of the concatentated MLST genes is optionally outputted, allowing for the creation of phylogenetic trees. This allows for rapid epidemilogical outbreak investigations.  

# References