#!/usr/bin/env bash
disease_with_pmid_and_hpo=`intersect_columns -a $INPUTS_PATH/$1""_pubmed_profiles.txt -b $INPUTS_PATH/$1""_hpo_profiles.txt -A 1 -B 1 -c | grep c | sed "s/c: //g"`
disease_PMIDs=`intersect_columns -a $INPUTS_PATH/$1""_pubmed_profiles.txt -b $INPUTS_PATH/$1""_hpo_profiles.txt -A 1 -B 1 --full | cut -f 2 | tr "," "\n" | sort -u | wc -l`

# FOR FIRST VENN DIAGRAM
echo -e "$1""_pmid_profiles\t`cat $INPUTS_PATH/$1""_pubmed_profiles.txt | wc -l`" > $RUN_TMP_PATH/number_of_records_$1.txt
echo -e "$1""_hpo_profiles\t`cat $INPUTS_PATH/$1""_hpo_profiles.txt | wc -l`" >> $RUN_TMP_PATH/number_of_records_$1.txt
echo -e "$1""_with_pmid_and_hpo\t$disease_with_pmid_and_hpo" >> $RUN_TMP_PATH/number_of_records_$1.txt

# FOR SECOND VENN DIAGRAM
echo -e "model_PMIDs\t`cat $RESULTS_PATH/llm_pmID_profiles.txt | wc -l`" >> $RUN_TMP_PATH/number_of_records_$1.txt
echo -e "$1""_PMIDs\t$disease_PMIDs" >> $RUN_TMP_PATH/number_of_records_$1.txt
echo -e "common_PMIDs\t`cat $RESULTS_PATH/llm_vs_$1""_semantic_similarity_hpo_based.txt | cut -f 1 | sort -u | wc -l`" >> $RUN_TMP_PATH/number_of_records_$1.txt


cp $RUN_TMP_PATH/number_of_records_$1.txt $RESULTS_PATH/number_of_records_$1.txt

#unique_common_pmids=`cut -f 2 $RUN_INPUTS_PATH/$1""_PMIDs_cleaned | tr "," "\n" | sort -u | wc -l`
#echo -e "unique_common_pmids\t$unique_common_pmids" >> $RUN_TMP_PATH/number_of_records_$1.txt
#cat $RUN_TMP_PATH/number_of_records_raw_$1.txt | tr " " "\t" | cut -f 1,2 > $RESULTS_PATH/number_of_records_$1.txt