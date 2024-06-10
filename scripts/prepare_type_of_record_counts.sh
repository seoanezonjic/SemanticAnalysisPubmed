#!/usr/bin/env bash
echo -e "llm_pmid_profiles\t`wc -l $RESULTS_PATH/llm_pmID_profiles.txt`" > $TMP_PATH/number_of_records_raw_$1.txt
echo -e "$1""_pmid_profiles\t`wc -l $INPUTS_PATH/$1""_pubmed_profiles.txt`" >> $TMP_PATH/number_of_records_raw_$1.txt
echo -e "$1""_hpo_profiles\t`wc -l $INPUTS_PATH/$1""_hpo_profiles.txt`" >> $TMP_PATH/number_of_records_raw_$1.txt
gold_with_pmid_and_hpo=`intersect_columns -a $INPUTS_PATH/$1""_pubmed_profiles.txt -b $INPUTS_PATH/$1""_hpo_profiles.txt -A 1 -B 1 -c | grep c | sed "s/c: //g"`
echo -e "$1""_with_pmid_and_hpo\t$gold_with_pmid_and_hpo" >> $TMP_PATH/number_of_records_raw_$1.txt
echo -e "llm_and_$1""_with_pmid_and_hpo\t`wc -l $TMP_PATH/$1""_pmids_and_hpos`" >> $TMP_PATH/number_of_records_raw_$1.txt
unique_common_pmids=`cut -f 2 $INPUTS_PATH/$1""_PMIDs_cleaned | tr "," "\n" | sort -u | wc -l`
echo -e "unique_common_pmids\t$unique_common_pmids" >> $TMP_PATH/number_of_records_raw_$1.txt
echo -e "filtered_rankings\t`wc -l $RESULTS_PATH/llm_vs_$1""_semantic_similarity_hpo_based.txt`" >> $TMP_PATH/number_of_records_raw_$1.txt
cat $TMP_PATH/number_of_records_raw_$1.txt | tr " " "\t" | cut -f 1,2 > $RESULTS_PATH/number_of_records_$1.txt