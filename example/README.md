# Example dataset
In the input_data subdirectory there are 3 published Salmonella genomes from different STs. A snapshot of the Salmonella MLST database is in this subdirectory.

```
cd example
export MLST_DATABASES=./mlst_databases
get_sequence_type -c -s 'Salmonella enterica' input_data/*.fa
```

The expected output files are located in the expected_output_data directory. Each of the 3 genomes has been assigned an ST and there is a file with the sequences of the alleles concatenated. This can then be used as input to RAxML to produce a basic phylogenetic tree.
