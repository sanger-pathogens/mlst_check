/software/pubseq/bin/ncbi-blast-2.2.25+/bin/makeblastdb -in contigs.fa  -dbtype nucl -parse_seqids -out output_contigs 

/software/pubseq/bin/ncbi-blast-2.2.25+/bin/blastn -task blastn -query Escherichia_coli_1/alleles/adk.tfa -db output_contigs -outfmt 7  -perc_identity 100