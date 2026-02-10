# PDG_DB: Plastic-Degrading Gene Database

## Overview
PDG_DB is the a comprehensive plastic-degrading gene database containing experimentally validated protein sequences and computationally predicted genes for plastic biodegradation research.

## Database Files

### Core Database Files

**`PDG_DB_protein.faa`**  
FASTA format file containing 341 experimentally validated protein sequences from the PDG_DB database. These sequences represent confirmed plastic-degrading enzymes with documented degradation activities.

**`PDG_DB_gene_type.tsv`**  
Gene type classification file for PDG_DB entries. Contains substrate-specific categorization of plastic-degrading genes based on their target plastic types and degradation mechanisms.

**`PDG_DB_protein_structures.tar.gz`**  
Compressed archive containing predicted three-dimensional protein structures for PDG_DB entries. These structural models can be used for molecular docking, binding site analysis, and enzyme engineering studies.

### Classification and Reference Files

**`Plastic_classification.txt`**  
Classification scheme for plastic-degrading genes based on their substrate specificity. Defines the categorization system used to group genes according to the types of plastic polymers they can degrade.

### Extended Database Files

**`Predicted_PDGs_Non-redundant.fa`**  
FASTA format file containing 3,612 non-redundant predicted plastic-degrading genes identified through large-scale multi-omics analysis. This represents the extended PDG_DB with computationally identified candidates.

**`Predicted_PDGs_gene_type.tsv`**  
Substrate classification file for the predicted PDGs. Contains the plastic type assignments and functional annotations for the computationally identified plastic-degrading gene candidates.

### Usage of the Database

**`build the database`** 
diamond makedb --in PDG_DB_protein.faa --db pdg_db_diamond --threads 8

**`Blastp search`** 
diamond blastp --db pdg_db_diamond --query input.fasta --out results.tsv --threads 8 --evalue 1e-5

**`PDG_DB Blast Results Organization and Annotation Reference Script`** 
PDG_DB_BLAST_annotation_pipeline.R

**`Automated Alignment and Data Processing Script`** 

chmod +x pdg_db_diamond_analysis.sh

./pdg_db_diamond_analysis.sh your_sequences.fasta


## Citation
If you use PDG_DB in your research, please cite: [https://github.com/Z-bioinfo/PDG_DB]

## Contact
For questions or issues, please contact: [zhangjiayu@dgut.edu.cn (Jiayu Zhang)]
