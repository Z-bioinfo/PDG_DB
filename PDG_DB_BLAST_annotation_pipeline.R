# Load required R packages
library(ggplot2)
library(tidyverse)
library(scales)
library(RColorBrewer)

# Read BLAST results and annotation files
# BLAST results file (example: output format 6 from DIAMOND BLASTP)
blast_res <- read.table("blast_output.tsv", sep="\t", header=FALSE)
# Add column names for BLAST output (assuming standard BLAST format 6)
colnames(blast_res) <- c("query_id", "target_id", "identity", "length", 
                         "mismatch", "gapopen", "qstart", "qend", 
                         "tstart", "tend", "evalue", "bitscore")

# Read gene type annotation
gene_type <- read.delim("PDG_DB_gene_type.tsv", sep="\t", header=TRUE)

# Read plastic classification
plastic_class <- read.delim("Plastic_classification.txt", sep="\t", header=TRUE)

# Merge BLAST results with gene type annotation
blast_annotated <- blast_res %>%
  left_join(gene_type, by=c("target_id" = "label")) %>%
  filter(!is.na(Plastic))  # Remove hits without plastic annotation

# Split multiple plastic types (comma-separated) into separate rows
blast_expanded <- blast_annotated %>%
  separate_rows(Plastic, sep=",\\s*")  # Split by comma with optional space

# Merge with plastic classification
blast_full <- blast_expanded %>%
  left_join(plastic_class, by=c("Plastic" = "Abbreviation"))

# Basic statistics
cat("Total BLAST hits:", nrow(blast_res), "\n")
cat("Annotated hits:", nrow(blast_annotated), "\n")
cat("Unique query sequences with hits:", length(unique(blast_res$query_id)), "\n")
cat("Unique PDG genes hit:", length(unique(blast_res$target_id)), "\n")

# Count hits per plastic type
plastic_counts <- blast_full %>%
  group_by(Plastic) %>%
  summarise(
    hit_count = n(),
    unique_queries = n_distinct(query_id),
    avg_identity = mean(identity),
    avg_bitscore = mean(bitscore)
  ) %>%
  arrange(desc(hit_count)) %>%
  left_join(select(plastic_class, Abbreviation, `Plastic.name`, Backbone.Type..L2.), 
            by=c("Plastic" = "Abbreviation"))

# Count hits per classification category
backbone_counts <- blast_full %>%
  group_by(Backbone.Type..L2.) %>%
  summarise(
    hit_count = n(),
    unique_queries = n_distinct(query_id)
  ) %>%
  arrange(desc(hit_count))

degradability_counts <- blast_full %>%
  group_by(Degradability) %>%
  summarise(
    hit_count = n(),
    unique_queries = n_distinct(query_id)
  ) %>%
  arrange(desc(hit_count))

feedstock_counts <- blast_full %>%
  group_by(Feedstock) %>%
  summarise(
    hit_count = n(),
    unique_queries = n_distinct(query_id)
  ) %>%
  arrange(desc(hit_count))

# Create visualization 1: Top plastic types by hit count
p1 <- ggplot(plastic_counts %>% top_n(20, hit_count), 
             aes(x=reorder(Plastic, hit_count), y=hit_count)) +
  geom_col(fill="#1F78B4") +
  coord_flip() +
  labs(x="Plastic Type", y="Number of BLAST Hits",
       title="Top 20 Plastic Types by BLAST Hit Count") +
  theme_minimal() +
  theme(axis.text = element_text(size=10),
        axis.title = element_text(size=12, face="bold"))

# Create visualization 2: Hits by backbone type
p2 <- ggplot(backbone_counts, 
             aes(x=reorder(Backbone.Type..L2., hit_count), y=hit_count)) +
  geom_col(fill="#33A02C") +
  coord_flip() +
  labs(x="Backbone Type", y="Number of BLAST Hits",
       title="BLAST Hits by Polymer Backbone Type") +
  theme_minimal() +
  theme(axis.text = element_text(size=10),
        axis.title = element_text(size=12, face="bold"))

# Create visualization 3: Hits by degradability
p3 <- ggplot(degradability_counts, 
             aes(x=reorder(Degradability, hit_count), y=hit_count)) +
  geom_col(fill="#E31A1C") +
  coord_flip() +
  labs(x="Degradability", y="Number of BLAST Hits",
       title="BLAST Hits by Plastic Degradability") +
  theme_minimal() +
  theme(axis.text = element_text(size=10),
        axis.title = element_text(size=12, face="bold"))

# Create visualization 4: Hits by feedstock
p4 <- ggplot(feedstock_counts, 
             aes(x=reorder(Feedstock, hit_count), y=hit_count)) +
  geom_col(fill="#FF7F00") +
  coord_flip() +
  labs(x="Feedstock", y="Number of BLAST Hits",
       title="BLAST Hits by Plastic Feedstock") +
  theme_minimal() +
  theme(axis.text = element_text(size=10),
        axis.title = element_text(size=12, face="bold"))

# Display plots
print(p1)
print(p2)
print(p3)
print(p4)

# Save results to files
write.table(blast_full, "blast_results_fully_annotated.tsv", 
            sep="\t", row.names=FALSE, quote=FALSE)
write.table(plastic_counts, "plastic_type_summary.tsv", 
            sep="\t", row.names=FALSE, quote=FALSE)

# Save plots to PDF
pdf("blast_results_analysis.pdf", width=10, height=8)
print(p1)
print(p2)
print(p3)
print(p4)
dev.off()

cat("\nAnalysis complete! Output files:\n")
cat("1. blast_results_fully_annotated.tsv - Fully annotated BLAST results\n")
cat("2. plastic_type_summary.tsv - Summary statistics by plastic type\n")
cat("3. blast_results_analysis.pdf - Visualization plots\n")