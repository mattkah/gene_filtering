#!/bin/zsh

#SBATCH --job-name gene_filter
#SBATCH --output gene.out 
#SBATCH --ntasks 1
#SBATCH --time 0-01:00

cd /Users/mattkahler/Desktop/gene_filter_data/gene_data/

# Filtering Ensembl data set for strictly gene regions of chromosomes 

awk '$3 == "gene" && $1 ~ /^[1-7]H/{print $1 "\t" $3 "\t" $4 "\t" $5 "\t" $9}' Hordeum_vulgare.MorexV3_pseudomolecules_assembly.60.gff3 > filtered_assembly.gff3

# Dataset for regions to search

sed 's/^chr//g' selected_regions.tsv| tail +2 | cut -f1,2,3 > search_regions.tsv

# Input files

cd ..

data1="gene_data/search_regions.tsv"
data2="gene_data/filtered_assembly.gff3"
data3="gene_data/Compara_protein_homologs.tsv" 

output_dir="output_data"
mkdir -p "$output_dir"

while IFS=$'\t' read -r line; do
 
    chr1=$(echo "$line" | awk '{print $1}')
    start1=$(echo "$line" | awk '{print $2}')
    end1=$(echo "$line" | awk '{print $3}')

   chromosome_dir="${output_dir}/${chr1}"
   mkdir -p "$chromosome_dir"

   output_file="${chromosome_dir}/${chr1}_${start1}_${end1}.tsv"

   matched_genes=$(awk -v chr="$chr1" -v start="$start1" -v end="$end1" \
   '$1 == chr && $3 >= start && $4 <= end {print $5}' "$data2")

   if [[ -n "$matched_genes" ]]; then
    for gene_id_mod in $matched_genes; do
      core=$(echo "$gene_id_mod" | awk -F '\t' '{if ($1 ~/ID=gene:/){match($1, /HORVU\.MOREX\.[^;]+/); print substr($1, RSTART, RLENGTH)}}')
    
    matching_species=$(grep -w "$core" "$data3")

    if [[ -n "$matching_species" ]]; then
      echo "$matching_species" >> "$output_file"
    fi
  done
 fi
done < "$data1"
