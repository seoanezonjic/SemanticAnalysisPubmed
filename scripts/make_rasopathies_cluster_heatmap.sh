#!/usr/bin/env bash
AGG_TOP10_FOLDER=$TOP10_RASO_FOLDER/aggregated_top10_tables
AGG_TOP10_TMP=$AGG_TOP10_FOLDER/tmp
PROOF_TMP=$PROOF_FOLDER/tmp
CLUSTERMAP_TMP=$PROOF_TMP/clustermap_tmp

mkdir -p $AGG_TOP10_FOLDER
mkdir -p $AGG_TOP10_TMP
mkdir -p $CLUSTERMAP_TMP

######## Prepare each rasopathy top10 aggregated table ############
#from this ---- pmid, rank, sim, title
#to this ------- pmid & MeanRank, title, Noonan Rank, NF Rank, Costello Rank, CFC Rank
prepare_raso_top10_aggr_table.py -f $TOP10_RASO_FOLDER -r "nf,noonan,costello,cfc" --top_n 15 -o $AGG_TOP10_FOLDER/aggregated_top10_table.txt

cut -f 1 $AGG_TOP10_FOLDER/aggregated_top10_table.txt > $RESULTS_PATH/rasopaties_top10_pmid_aggregated
echo -e "PubMed ID\tNoonan Rank\tNF Rank\tCostello Rank\tCFC Rank" > $AGG_TOP10_TMP/overlays.txt
tail -n +2 $AGG_TOP10_FOLDER/aggregated_top10_table.txt | cut -f 1,4,5,6,7 >> $AGG_TOP10_TMP/overlays.txt
cp $AGG_TOP10_TMP/overlays.txt $PROOF_TMP/overlays.txt

######### Prepare clustermap ###############
grep -wf $RESULTS_PATH/rasopaties_top10_pmid_aggregated $RESULTS_PATH/llm_pmID_profiles.txt > $PROOF_TMP/rasopaties_top10_pmid_aggregated_profiles
cat $PROOF_TMP/rasopaties_top10_pmid_aggregated_profiles | \
	semtools -i - -S "," -O HPO --similarity_cluster_plot lin --output_report $RESULTS_PATH/proof_of_concept/raso_heatmap.html
text2binary_matrix --input_file $CLUSTERMAP_TMP/similarity_matrix_lin.npy --input_type bin \
				   --output_file $CLUSTERMAP_TMP/similarity_matrix_lin.txt --output_type matrix

echo -e 'tree_path\t'$CLUSTERMAP_TMP'/lin_linkage.dnd' > $CLUSTERMAP_TMP/tree_path
data_paths=`echo -e "
    $CLUSTERMAP_TMP/similarity_matrix_lin.txt,
    $CLUSTERMAP_TMP/tree_path,
    $CLUSTERMAP_TMP/similarity_matrix_lin_x.lst,
    $CLUSTERMAP_TMP/lin_clusters.txt,
    $PROOF_TMP/overlays.txt,
    $AGG_TOP10_FOLDER/aggregated_top10_table.txt
    " | tr -d [:space:]`
report_html -d $data_paths \
            -t $REPORTS_TEMPLATES/top10_clustermap_and_table.txt \
            -o $PROOF_FOLDER/top10_clustermap_and_table