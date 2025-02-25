#!/usr/bin/env bash

AUTOFLOW_PATH=$1/get_corpus_index_0000
RESULTS_PATH=$2
PMID=$3
HPO=$4

pmid_chunk_file=`grep $PMID $AUTOFLOW_PATH/pmids_file_locator.txt | cut -f 1`
zgrep -w "^$PMID" $AUTOFLOW_PATH/indexes/$pmid_chunk_file | cut -f 2 > ./tmp/pmid_sentences.txt
grep $PMID $RESULTS_PATH/llm_pmID_profiles_with_cosine_sim.txt | cut -f 1,2,4 > ./tmp/pmid_hpos_locs.txt

find_matched_sentence.py --query_hpo $HPO --sentences ./tmp/pmid_sentences.txt --hpo_locs ./tmp/pmid_hpos_locs.txt

rm ./tmp/pmid_sentences.txt
rm ./tmp/pmid_hpos_locs.txt