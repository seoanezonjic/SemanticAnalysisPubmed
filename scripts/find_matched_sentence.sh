#!/usr/bin/env bash

FIND_MATCH_FOLDER="./tmp/find_matched_sentence"
mkdir -p $FIND_MATCH_FOLDER

RESULTS_PATH=$1
PMID=$2
HPO=$3

pmid_chunk_file=`grep $PMID $PREPARED_CORPUS/../$DOCUMENT_TYPE"_pmids_file_locator.txt" | cut -f 1 | head -n 1`
echo "PMID:$PMID is in $pmid_chunk_file"

zgrep -w "^$PMID" $PREPARED_CORPUS/$pmid_chunk_file | gzip > $FIND_MATCH_FOLDER/target_pmid_wholedata.gz
zcat $FIND_MATCH_FOLDER/target_pmid_wholedata.gz | cut -f 2 > $FIND_MATCH_FOLDER/pmid_sentences.txt
grep $HPO $QUERIES_PATH/hpo_list > $FIND_MATCH_FOLDER/query_hpo.txt

#zgrep -w "^$PMID" $PREPARED_CORPUS/$pmid_chunk_file | cut -f 2 > $FIND_MATCH_FOLDER/pmid_sentences.txt
grep $PMID $RESULTS_PATH/llm_pmID_profiles_with_cosine_sim.txt | cut -f 1,2,4 > $FIND_MATCH_FOLDER/pmid_hpos_locs.txt

stEngine -m $MODEL_NAME -p $CURRENT_MODEL --print_relevant_pairs \
             -c $FIND_MATCH_FOLDER/target_pmid_wholedata.gz -q $FIND_MATCH_FOLDER/query_hpo.txt \
             -k $TOP_K -t $HARD_MIN_SIMILARITY -o $FIND_MATCH_FOLDER/ \
             $USE_GPU_FOR_SIM_CALC -g "cuda:0" $SPLIT_DOC --chunk_size $TEXT_BALANCE_SIZE #-v
#find_matched_sentence.py --query_hpo $HPO --sentences ./tmp/pmid_sentences.txt --hpo_locs ./tmp/pmid_hpos_locs.txt

#rm ./tmp/pmid_sentences.txt
#rm ./tmp/pmid_hpos_locs.txt