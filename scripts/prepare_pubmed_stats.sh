#!/usr/bin/env bash

##### COPYING FILES FOR PUBMED DOWNLOADS STATS #####
#COPYING FILES FOR PUBMED DOWNLOADS
cat $GS_SPECIFIC_BASE_PATH"/splitpaper/results/abstracts_stats_tables/total_stats" | transpose_table -i - > $PUBMED_FOLD/paper_total_stats
cat $GS_SPECIFIC_BASE_PATH"/splitabstract/results/abstracts_stats_tables/total_stats" | transpose_table -i - > $PUBMED_FOLD/abstract_total_stats

pap_anot=`cat $GS_SPECIFIC_BASE_PATH"/splitpaper/results/llm_pmID_profiles.txt" | wc -l`
abs_anot=`cat $GS_SPECIFIC_BASE_PATH"/splitabstract/results/llm_pmID_profiles.txt" | wc -l`
echo -e "annotated\t$pap_anot" >> $PUBMED_FOLD/paper_total_stats
echo -e "annotated\t$abs_anot" >> $PUBMED_FOLD/abstract_total_stats

#COPYING FILES FOR PUBMED YEARS
cat $GS_SPECIFIC_BASE_PATH"/splitpaper/results/pubmed_metadata" | cut -f 1,3 > $PUBMED_FOLD/paper_years
cat $GS_SPECIFIC_BASE_PATH"/splitabstract/results/pubmed_metadata" | cut -f 1,3 > $PUBMED_FOLD/abstract_years

#COPYING FILES FOR PUBMED PROFILE SIZES
cat $GS_SPECIFIC_BASE_PATH"/splitpaper/results/llm_pmID_profiles.txt" | cut -f 2 | awk 'BEGIN{FS=","}{print NF}' > $PUBMED_FOLD/paper_profile_sizes
cat $GS_SPECIFIC_BASE_PATH"/splitabstract/results/llm_pmID_profiles.txt" | cut -f 2 | awk 'BEGIN{FS=","}{print NF}' > $PUBMED_FOLD/abstract_profile_sizes
cat $INPUTS_PATH"/omim_hpo_profiles.txt" | cut -f 2 | awk 'BEGIN{FS=","}{print NF}' > $PUBMED_FOLD/omim_profile_sizes