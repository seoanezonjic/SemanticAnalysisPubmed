#!/usr/bin/env bash
echo -e "llm_pmid_profiles\t`wc -l $RESULTS_PATH/llm_pmID_profiles.txt`" > $TMP_PATH/number_of_records_raw.txt
echo -e "mondo_pmid_profiles\t`wc -l $INPUTS_PATH/mondo_pubmed_profiles.txt`" >> $TMP_PATH/number_of_records_raw.txt
echo -e "mondo_hpo_profiles\t`wc -l $INPUTS_PATH/mondo_hpo_profiles.txt`" >> $TMP_PATH/number_of_records_raw.txt
mondos_with_pmid_and_hpo=`intersect_columns -a $INPUTS_PATH/mondo_pubmed_profiles.txt -b $INPUTS_PATH/mondo_hpo_profiles.txt -A 1 -B 1 -c | grep c | sed "s/c: //g"`
echo -e "mondos_with_pmid_and_hpo\t$mondos_with_pmid_and_hpo" >> $TMP_PATH/number_of_records_raw.txt
echo -e "llm_and_mondo_with_pmid_and_hpo\t`wc -l $TMP_PATH/mondo_pmids_and_hpos`" >> $TMP_PATH/number_of_records_raw.txt
unique_common_pmids=`cut -f 2 $INPUTS_PATH/MONDO_PMIDs_cleaned | tr "," "\n" | sort -u | wc -l`
echo -e "unique_common_pmids\t$unique_common_pmids" >> $TMP_PATH/number_of_records_raw.txt
echo -e "filtered_rankings\t`wc -l $RESULTS_PATH/llm_vs_mondo_semantic_similarity_hpo_based.txt`" >> $TMP_PATH/number_of_records_raw.txt
cat $TMP_PATH/number_of_records_raw.txt | tr " " "\t" | cut -f 1,2 > $RESULTS_PATH/number_of_records.txt