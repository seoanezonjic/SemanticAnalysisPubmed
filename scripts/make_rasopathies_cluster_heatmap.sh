#!/usr/bin/env bash
AGG_TOP10_FOLDER=$TOP10_RASO_FOLDER/aggregated_top10_tables
AGG_TOP10_TMP=$AGG_TOP10_FOLDER/tmp
PROOF_TMP=$PROOF_FOLDER/tmp
CLUSTERMAP_TMP=$PROOF_TMP/clustermap_tmp
CORPUS_FOLDER=$PREPARED_CORPUS

mkdir -p $AGG_TOP10_FOLDER
mkdir -p $AGG_TOP10_TMP
mkdir -p $CLUSTERMAP_TMP; rm $CLUSTERMAP_TMP/*

rasos="nf,nf-noonan,noonan,costello,cfc"
rasos_ranks="NF1,NFNS,Noonan,Costello,CFC"

rasos_ranks_titles="PubMed ID\t`echo $rasos_ranks | sed -E 's/,/\\\t/g'`"  

####### Prepare each rasopathy top10 aggregated table ############
##from this ---- pmid, rank, sim, title
##to this ------- pmid & MeanRank, title, Noonan Rank, NF Rank, Costello Rank, CFC Rank
prepare_raso_top10_aggr_table.py -f $TOP10_RASO_FOLDER -r $rasos --top_n 10 -o $AGG_TOP10_FOLDER/aggregated_top10_table.txt
cut -f 1 $AGG_TOP10_FOLDER/aggregated_top10_table.txt | tail -n +2 > $AGG_TOP10_TMP/aggregated_top10_pmids

grep -wf $AGG_TOP10_TMP/aggregated_top10_pmids $CORPUS_FOLDER/../$DOCUMENT_TYPE"_pmids_file_locator.txt" | cut -f 1 | \
    awk -v fold=$CORPUS_FOLDER '{print fold"/"$1}' > $AGG_TOP10_TMP/files_to_grep

cat $AGG_TOP10_TMP/files_to_grep | xargs zcat | grep -wf $AGG_TOP10_TMP/aggregated_top10_pmids | cut -f 1,2 > $AGG_TOP10_TMP/top10_pmids_and_fulltext

prepare_latex_top10_table.py -i $AGG_TOP10_FOLDER/aggregated_top10_table.txt \
                             -p $AGG_TOP10_TMP/top10_pmids_and_fulltext \
                             -o $AGG_TOP10_FOLDER/aggregated_top10_latex_table.txt


######### Prepare clustermap ###############
cut -f 1 $AGG_TOP10_FOLDER/aggregated_top10_table.txt > $RESULTS_PATH/rasopaties_top10_pmid_aggregated
echo -e $rasos_ranks_titles > $AGG_TOP10_TMP/overlays.txt
tail -n +2 $AGG_TOP10_FOLDER/aggregated_top10_table.txt | cut -f 1,4,5,6,7,8 >> $AGG_TOP10_TMP/overlays.txt
cp $AGG_TOP10_TMP/overlays.txt $PROOF_TMP/overlays.txt

grep -wf $RESULTS_PATH/rasopaties_top10_pmid_aggregated $RESULTS_PATH/llm_pmID_profiles.txt > $PROOF_TMP/rasopaties_top10_pmid_aggregated_profiles
cat $PROOF_TMP/rasopaties_top10_pmid_aggregated_profiles | \
	semtools -i - -S "," -O HPO --similarity_cluster_plot lin --output_report $RESULTS_PATH/proof_of_concept/raso_heatmap.html
text2binary_matrix --input_file $CLUSTERMAP_TMP/similarity_matrix_lin.npy --input_type bin \
				   --output_file $CLUSTERMAP_TMP/similarity_matrix_lin.txt --output_type matrix

echo -e 'tree_path\t'$CLUSTERMAP_TMP'/lin_linkage.dnd' > $CLUSTERMAP_TMP/tree_path
echo -e 'ont_sim_method\t'$ont_sim_method > $CLUSTERMAP_TMP/ont_sim_method
data_paths=`echo -e "
    $CLUSTERMAP_TMP/similarity_matrix_lin.txt,
    $CLUSTERMAP_TMP/tree_path,
    $CLUSTERMAP_TMP/similarity_matrix_lin_x.lst,
    $CLUSTERMAP_TMP/lin_clusters.txt,
    $PROOF_TMP/overlays.txt,
    $AGG_TOP10_FOLDER/aggregated_top10_table.txt,
    $CLUSTERMAP_TMP/ont_sim_method
    " | tr -d [:space:]`
report_html -d $data_paths \
            -t $REPORTS_TEMPLATES/top10_clustermap_and_table.txt \
            -o $PROOF_FOLDER/top10_clustermap_and_table
cp $AGG_TOP10_FOLDER/aggregated_top10_latex_table.txt $PROOF_FOLDER/aggregated_top10_latex_table.txt