#!/usr/bin/env bash
mkdir -p $METAREPORT_RESULTS_PATH

##### COPYING FILES FOR METAREPORT RANKINGS #####
cp $CURRENT_PATH"/runs/OMIM_DO/splitpaper/results/llm_pmID_profiles.txt" $METAREPORT_RESULTS_PATH/do_papers_llm_pmID_profiles.txt
cp $CURRENT_PATH"/runs/OMIM_DO/splitabstract/results/llm_pmID_profiles.txt" $METAREPORT_RESULTS_PATH/do_abstracts_llm_pmID_profiles.txt
cp $CURRENT_PATH"/runs/OMIM_ehrhart/splitpaper/results/llm_pmID_profiles.txt" $METAREPORT_RESULTS_PATH/ehrhart_papers_llm_pmID_profiles.txt
cp $CURRENT_PATH"/runs/OMIM_ehrhart/splitabstract/results/llm_pmID_profiles.txt" $METAREPORT_RESULTS_PATH/ehrhart_abstracts_llm_pmID_profiles.txt
cat $METAREPORT_RESULTS_PATH/../disease* > $METAREPORT_RESULTS_PATH/all_disease_data
cat $METAREPORT_RESULTS_PATH/../phenotype* > $METAREPORT_RESULTS_PATH/all_phenotype_data
if [ ! -s $METAREPORT_RESULTS_PATH/pmid_titles ]; then cut -f 1 $METAREPORT_RESULTS_PATH/all_phenotype_data | sort -u | get_pmid_titles.py -i - -o $METAREPORT_RESULTS_PATH/pmid_titles ;fi


##### COPYING AND PREPARING GOLD STANDARD STANDARD COUNTS TABLES #####
head -n 1 $META_GS_COUNTS_FOLD/do_papers_phenotype > $META_GS_COUNTS_FOLD_JOINED/phenotype_counts
tail -q -n 1 $META_GS_COUNTS_FOLD/*_phenotype >> $META_GS_COUNTS_FOLD_JOINED/phenotype_counts
transpose_table -i $META_GS_COUNTS_FOLD_JOINED/phenotype_counts | awk 'BEGIN{OFS="\t"}{print $1,$2,$4,$3,$5}' > $META_GS_COUNTS_FOLD_JOINED/phenotype_counts_transposed
rm $META_GS_COUNTS_FOLD_JOINED/phenotype_counts; mv $META_GS_COUNTS_FOLD_JOINED/phenotype_counts_transposed $META_GS_COUNTS_FOLD_JOINED/phenotype_gs_counts

head -n 1 $META_GS_COUNTS_FOLD/do_papers_disease > $META_GS_COUNTS_FOLD_JOINED/disease_counts
tail -q -n 1 $META_GS_COUNTS_FOLD/*_disease >> $META_GS_COUNTS_FOLD_JOINED/disease_counts
transpose_table -i $META_GS_COUNTS_FOLD_JOINED/disease_counts | awk 'BEGIN{OFS="\t"}{print $1,$2,$4,$3,$5}' > $META_GS_COUNTS_FOLD_JOINED/disease_counts_transposed
rm $META_GS_COUNTS_FOLD_JOINED/disease_counts; mv $META_GS_COUNTS_FOLD_JOINED/disease_counts_transposed $META_GS_COUNTS_FOLD_JOINED/disease_gs_counts