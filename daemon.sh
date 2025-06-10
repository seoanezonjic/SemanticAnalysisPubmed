#! /usr/bin/env bash
source ~soft_bio_267/initializes/init_python
export CURRENT_PATH=`pwd`


export PYENV=$CURRENT_PATH/llm_env #TODO: Remove later
#python -m venv `basename $PYENV` --system-site-packages
source $PYENV/bin/activate #TODO: Remove later
#pip install -e $HOME/dev_py/NetAnalyzer
#pip install -e $HOME/dev_py/py_exp_calc
#pip install -e $HOME/dev_py/py_semtools
#pip install -e $HOME/dev_py/exp/py_report_html
#pip install matplotlib_venn
#pip install metapub
#pip install wordcloud
export PATH=$PYENV/bin:$PATH

############# GENERAL PATHS
export PAPER_REPORTS=$CURRENT_PATH/reports_for_the_paper
export INPUTS_PATH=$CURRENT_PATH/inputs
export QUERIES_PATH=$CURRENT_PATH/queries
export TMP_PATH=$CURRENT_PATH/tmp
export CODE_PATH=$CURRENT_PATH/scripts
export TEMPLATES_PATH=$CURRENT_PATH/templates
export AUTOFLOW_TEMPLATES=$TEMPLATES_PATH/autoflow
export REPORTS_TEMPLATES=$TEMPLATES_PATH/reports
export OTHER_STATS_PATH=$CURRENT_PATH/other_stats

export MODEL_PATH=$CURRENT_PATH/models
#export MODEL_NAME="pritamdeka/S-PubMedBert-MS-MARCO"
export MODEL_NAME="all-mpnet-base-v2" #export MODEL_NAME="all-MiniLM-L6-v2"
export CURRENT_MODEL=$MODEL_PATH/$MODEL_NAME 

export OMIM_QUERY_INPUT_DATA="/mnt/home/users/bio_267_uma/federogc/projects/GraphPrioritizer/control_genes/zampieri/data/omim_data/mimTitles.txt" #For OMIM list as query
export PATH=$CODE_PATH:$PATH

export PUBMED_CHUNKSIZE_FILT=100

################### CONFIG DAEMON STARTS TO BEING APLIED HERE
source $1

#export METAREPORT_RESULTS_PATH=$CURRENT_PATH"/global_results/no_random_negatives/metareport"
export METAREPORT_RESULTS_PATH=$CURRENT_PATH/global_results/$MODEL_NAME/$METAREPORT_CASE/metareport

################### RUN SPECIFIC PATHS
echo "DOING $RUN_NAME RUN WITH MODEL $MODEL_NAME"
export RUN_FOLDER=$CURRENT_PATH"/runs/$MODEL_NAME/"$RUN_NAME
export RUN_INPUTS_PATH=$RUN_FOLDER/"inputs"
export RUN_TMP_PATH=$RUN_FOLDER/"tmp"
export RESULTS_PATH=$RUN_FOLDER/"results"
export PUBMED_FILES_STATS_PATH=$RESULTS_PATH/abstracts_stats_tables

#PATHS TO EXECUTION OF TEMPLATES
export PHENOTYPE_ANNOTATION_TEMPLATE_PATH=$AUTOFLOW_TEMPLATES/$PHENOTYPE_ANNOTATION_TEMPLATE

export CORPUS_PREP_EXEC_PATH=$FSCRATCH"/SemanticAnalysisPubmed/CORPUS_PREPARATION/execs/$DOCTYPE_PLACEHOLDER_VAR"
export ZEROBENCH_EXEC_PATH=$FSCRATCH"/SemanticAnalysisPubmed/MODELS/$MODEL_NAME/$RUN_NAME/EXECS_zerobench"
export ENGINE_EXEC_PATH=$FSCRATCH"/SemanticAnalysisPubmed/MODELS/$MODEL_NAME/$RUN_NAME/EXECS_engine"
export PROFILES_EXEC_PATH=$FSCRATCH"/SemanticAnalysisPubmed/MODELS/$MODEL_NAME/$RUN_NAME/EXECS_profiles"
export PROOF_EXEC_PATH=$FSCRATCH"/SemanticAnalysisPubmed/MODELS/$MODEL_NAME/$RUN_NAME/EXECS_proof"

echo -e "phen_annot_wf\t$ENGINE_EXEC_PATH" > $CURRENT_PATH/workflow_paths
echo -e "phen_bench_wf\t$PROFILES_EXEC_PATH" >> $CURRENT_PATH/workflow_paths
echo -e "dis_annot_and_bench_wf\t$ZEROBENCH_EXEC_PATH" >> $CURRENT_PATH/workflow_paths
echo -e "raso_wf\t$PROOF_EXEC_PATH" >> $CURRENT_PATH/workflow_paths
echo -e "prepare_corpus\t$CORPUS_PREP_EXEC_PATH" >> $CURRENT_PATH/workflow_paths

export GS_TYPE=`echo $RUN_NAME | cut -f 1 -d "/"`
export GS_SPECIFIC_BASE_PATH=$CURRENT_PATH"/runs/"$MODEL_NAME"/"$GS_TYPE
export PUBMED_FOLD=$METAREPORT_RESULTS_PATH/PUBMED_STATS/$GS_TYPE
export PUBMED_REPORT=$METAREPORT_RESULTS_PATH/PUBMED_REPORT
export META_GS_COUNTS_FOLD=$METAREPORT_RESULTS_PATH/GS_COUNTS_STATS
export META_GS_COUNTS_FOLD_JOINED=$METAREPORT_RESULTS_PATH/GS_COUNTS_STATS_JOINED 

export PROOF_FOLDER=$RESULTS_PATH/proof_of_concept
export TOP10_RASO_FOLDER=$PROOF_FOLDER/top10_rasopathies
#CREATE FOLDERS
mkdir -p $RESULTS_PATH; mkdir -p $RESULTS_PATH/reports; mkdir -p $RESULTS_PATH/reports/cohort_stEngine; mkdir -p $INPUTS_PATH ; mkdir -p $TMP_PATH
mkdir -p $PUBMED_FILES_STATS_PATH; mkdir -p $AUTOFLOW_TEMPLATES; mkdir -p $REPORTS_TEMPLATES; mkdir -p $TEMPLATES_PATH; 
mkdir -p $RUN_FOLDER; mkdir -p $RUN_TMP_PATH; mkdir -p $RUN_INPUTS_PATH; mkdir -p $METAREPORT_RESULTS_PATH; mkdir -p $PYENV;
mkdir -p $OTHER_STATS_PATH; mkdir -p $RESULTS_PATH/GS_COUNTS_STATS;
mkdir -p $PUBMED_FOLD; mkdir -p $META_GS_COUNTS_FOLD; mkdir -p $META_GS_COUNTS_FOLD_JOINED
mkdir -p $PROOF_FOLDER; mkdir -p $TOP10_RASO_FOLDER; mkdir -p $PUBMED_REPORT; mkdir -p $PAPER_REPORTS/latex_tables
mkdir -p $PREPARED_CORPUS; mkdir -p $CORPUS_PREP_EXEC_PATH; mkdir -p $TMP_PATH/$DOCTYPE_PLACEHOLDER_VAR

#BLACKLISTED WORDS FOR PROOF OF CONCEPT HEATMAP
BLACKLIST_FLAG=""
if [ -n "$TITLE_BLACKLISTED_WORDS" ]; then
	echo -e $TITLE_BLACKLISTED_WORDS | tr ";" "\n" > $TMP_PATH/$DOCTYPE_PLACEHOLDER_VAR/blacklisted_words.txt
	BLACKLIST_FLAG="--filter_by_blacklist:$TMP_PATH/$DOCTYPE_PLACEHOLDER_VAR/blacklisted_words.txt"
fi

#OTHER VARIABLES
export database_ids="OMIM ORPHA"

if [ "$2" == "prepare_gs" ]; then #DOWNLOAD AND PREPARE GOLD STANDARDS TO ASSESS MODEL PERFORMANCE
		prepare_all_goldstandards.sh

elif [ "$2" == "down_model" ] ; then # DOWNLOAD EMBEDDING MODEL
		mkdir -p $MODEL_PATH
		stEngine -m $MODEL_NAME -p $CURRENT_MODEL -v

elif [ "$2" == "prepare_queries" ] ; then #Prepare queries for the workflows
		mkdir -p $QUERIES_PATH
		prepare_all_queries.sh
elif [ "$2" == "prepare_corpus" ] ; then #Prepare queries for the workflows
		mkdir -p $ENGINE_EXEC_PATH; 
		source ~soft_bio_267/initializes/init_autoflow
		variables=`echo -e "
			\\$code_path=$CODE_PATH,
			\\$pyenv=$PYENV,			
			\\$pubmed_path=$CORPUS_PATH,
			\\$prepared_corpus=$PREPARED_CORPUS,
			\\$split_doc=$SPLIT_DOC,
			\\$doc_type=$DOC_TYPE,
			\\$document_type=$DOCUMENT_TYPE,
			\\$equivalences=$EQUIVALENCES,
			\\$chunksize=$CHUNKSIZE,
			\\$pubmed_items_per_file=$PUBMED_ITEMS_PER_FILE,
			\\$text_balance_size=$TEXT_BALANCE_SIZE,
			\\$blacklist_flag=$BLACKLIST_FLAG,
			\\$title_blacklisted_words=$RUN_TMP_PATH/blacklisted_words.txt
			" | tr -d [:space:]`
		AutoFlow -e -w $AUTOFLOW_TEMPLATES/prepare_corpus.af -V $variables -o $CORPUS_PREP_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -c 10 -L $3
elif [ "$2" == "dis_annot_and_bench_wf" ] ; then #Direct Disease Prediction (DDP) workflow (annotation and benchmark)
		mkdir -p $ZEROBENCH_EXEC_PATH
		source ~soft_bio_267/initializes/init_autoflow
		variables=`echo -e "
			\\$code_path=$CODE_PATH,
			\\$model_name=$MODEL_NAME,
			\\$current_model=$CURRENT_MODEL,
			\\$queries=$QUERIES_PATH/omim_list,
			\\$prepared_corpus=$PREPARED_CORPUS,
			\\$doctype_placeholder_var=$DOCTYPE_PLACEHOLDER_VAR,
			\\$pyenv=$PYENV,
			\\$gpu_devices=$GPU_DEVICES,
			\\$n_gpus=$N_GPUs,
			\\$use_gpu_for_sim_calc=$USE_GPU_FOR_SIM_CALC,
			\\$parallel_folders_basename=$PARALLEL_FOLDERS_BASENAME,
			\\$folders_to_parallelize=$FOLDERS_TO_PARALLELIZE,
			\\$tsv_folder=$TSV_FOLDERS,
			\\$n_parallel_folders=$N_PARALLEL_FOLDERS,
			\\$chunksize=$CHUNKSIZE,
			\\$text_balance_size=$TEXT_BALANCE_SIZE,
			\\$after_filter_size=$AFTER_FILTER_SIZE,
			\\$results_path=$RESULTS_PATH,
			\\$report_templates_path=$REPORTS_TEMPLATES,
			\\$omim_file=$INPUTS_PATH/$ZEROBENCH_GOLD_STANDARD,
			\\$metareport_tag=$METAREPORT_TAG,
			\\$metareport_results_path=$METAREPORT_RESULTS_PATH,
			\\$add_random_papers=$ADD_RANDOM_PAPERS,
			\\$gs_vs_random_ratio=$GS_VS_RANDOM_RATIO,
			\\$other_stats_path=$OTHER_STATS_PATH		       
			" | tr -d [:space:]`
		AutoFlow -e -w $AUTOFLOW_TEMPLATES/disease_annotation_and_bench.af -V $variables -o $ZEROBENCH_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -c 10 -L $3

elif [ "$2" == "phen_annot_wf" ] ; then #Indirect Phenotype-based Disease Prediction (IPDP) workflow (annotation)
		mkdir -p $ENGINE_EXEC_PATH; 
		source ~soft_bio_267/initializes/init_autoflow
		variables=`echo -e "
			\\$code_path=$CODE_PATH,
			\\$model_name=$MODEL_NAME,
			\\$current_model=$CURRENT_MODEL,
			\\$soft_min_similarity=$SOFT_MIN_SIMILARITY,
			\\$hard_min_similarity=$HARD_MIN_SIMILARITY,
			\\$top_k=$TOP_K,
			\\$prepared_corpus=$PREPARED_CORPUS,
			\\$doctype_placeholder_var=$DOCTYPE_PLACEHOLDER_VAR,
			\\$queries=$QUERIES_PATH/hpo_list,
			\\$pyenv=$PYENV,
			\\$gpu_devices=$GPU_DEVICES,
			\\$n_gpus=$N_GPUs,
			\\$use_gpu_for_sim_calc=$USE_GPU_FOR_SIM_CALC,
			\\$parallel_folders_basename=$PARALLEL_FOLDERS_BASENAME,
			\\$folders_to_parallelize=$FOLDERS_TO_PARALLELIZE,
			\\$tsv_folder=$TSV_FOLDERS,
			\\$n_parallel_folders=$N_PARALLEL_FOLDERS,
			\\$chunksize=$CHUNKSIZE,
			\\$text_balance_size=$TEXT_BALANCE_SIZE,
			\\$prefilter_pmids_file=$PREFILTER_PMIDS_FILE,
			\\$after_filter_size=$AFTER_FILTER_SIZE,
			\\$results_path=$RESULTS_PATH,
			\\$tmp_path=$RUN_TMP_PATH,
			\\$report_templates_path=$REPORTS_TEMPLATES,
			\\$add_random_papers=$ADD_RANDOM_PAPERS,
			\\$file_to_get_random=$FILE_TO_GET_RANDOM,
			\\$gs_vs_random_ratio=$GS_VS_RANDOM_RATIO,
			\\$title_blacklisted_words=$RUN_TMP_PATH/blacklisted_words.txt,
			\\$pytorch_cuda_alloc_conf=$PYTORCH_CUDA_ALLOC_CONF,
			\\$diseases_with_pmid_and_phens_raw=$INPUTS_PATH/$DISEASES_WITH_PMID_AND_PHENS_RAW,
			\\$metareport_tag=$METAREPORT_TAG,
			\\$metareport_results_path=$METAREPORT_RESULTS_PATH		       
			" | tr -d [:space:]`
		AutoFlow -e -w $PHENOTYPE_ANNOTATION_TEMPLATE_PATH -V $variables -o $ENGINE_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -c 10 -L $3

elif [ "$2" == "prepare_phen_bench" ]; then #PREPARE DATA FOR IPDP EVALUATION
		for GOLD in $GOLD_STANDARDS; do
			echo "Preparing $GOLD benchmark"
			#Get GS HPO profiles with PMIDs (general, not specific to the model)
			cut -f 1 $INPUTS_PATH/$GOLD"_pubmed_profiles.txt" | sort -u > $TMP_PATH/$GOLD"_diseaseIDs_with_pmids"
			grep -wf $TMP_PATH/$GOLD"_diseaseIDs_with_pmids" $INPUTS_PATH/$GOLD"_hpo_profiles.txt" > $INPUTS_PATH/general_$GOLD"_hpo_profiles"
			#Get Model and Disease common pmIDs
			desaggregate_column_data -i $INPUTS_PATH/$GOLD"_pubmed_profiles.txt" -x 2 | aggregate_column_data -i - -x 2 -a 1 > $RUN_TMP_PATH/reverse_aggregated_$GOLD"_pmid_profiles.txt"
			intersect_columns -a $RUN_TMP_PATH/reverse_aggregated_$GOLD"_pmid_profiles.txt" -b $RESULTS_PATH/llm_pmID_profiles_with_randoms.txt -A 1 -B 1 --k c --full |\
							cut -f 1,2 | desaggregate_column_data -i - -x 2 | aggregate_column_data -i - -x 2 -a 1 | sort -u > $RUN_TMP_PATH/$GOLD"_pubmed_profiles_common_pmids.txt"

			#Get Disease IDs with both HPO and pmID profiles
			intersect_columns -a $RUN_TMP_PATH/$GOLD"_pubmed_profiles_common_pmids.txt" -b $INPUTS_PATH/$GOLD"_hpo_profiles.txt" -A 1 -B 1 --k c --full > $RUN_TMP_PATH/$GOLD"_pmids_and_hpos" 
			cut -f 1,2 $RUN_TMP_PATH/$GOLD"_pmids_and_hpos" | sort -u > $RUN_INPUTS_PATH/$GOLD"_PMIDs_cleaned"
			cut -f 3,4 $RUN_TMP_PATH/$GOLD"_pmids_and_hpos" | sort -u > $RUN_INPUTS_PATH/$GOLD"_HPOs_cleaned"
			cut -f 1 $RUN_TMP_PATH/$GOLD'_pmids_and_hpos' > $RUN_TMP_PATH/$GOLD'_PMID_HPO_common_IDs'
		done

elif [ "$2" == "phen_bench_wf" ]; then #Indirect Phenotype-based Disease Prediction (IPDP) workflow (benchmark)
		source ~soft_bio_267/initializes/init_autoflow

		for GOLD in $GOLD_STANDARDS; do
			#Get the number of records to process and the package size
			RECORDS_NUMBER=`wc -l $RUN_TMP_PATH/$GOLD'_PMID_HPO_common_IDs' | cut -f 1 -d " "`
			PACKAGE_NUMBER=`echo "$RECORDS_NUMBER / $BENCH_PACKAGE_SIZE" | bc`

			variables=`echo -e "
						\\$pyenv=$PYENV,
						\\$results_path=$RESULTS_PATH,
						\\$code_path=$CODE_PATH,
						\\$mondo_pmid_hpo_common_ids=$RUN_TMP_PATH/$GOLD'_PMID_HPO_common_IDs',
						\\$mondo_pmID_profiles=$RUN_INPUTS_PATH/$GOLD'_PMIDs_cleaned',
						\\$mondo_hpo_profiles=$RUN_INPUTS_PATH/$GOLD'_HPOs_cleaned',
						\\$llm_pmID_profiles=$RESULTS_PATH/llm_pmID_profiles.txt,
						\\$pubmed_metadata=$RESULTS_PATH/pubmed_metadata,
						\\$package_number="0-$PACKAGE_NUMBER",
						\\$package_size=$BENCH_PACKAGE_SIZE,
						\\$report_templates_path=$REPORTS_TEMPLATES,
						\\$gold=$GOLD,
						\\$metareport_tag=$METAREPORT_TAG,
						\\$metareport_results_path=$METAREPORT_RESULTS_PATH,
						\\$ont_sim_method=$ONT_SIM_METHOD
						" | tr -d [:space:]`
			#AutoFlow -e -w $AUTOFLOW_TEMPLATES/disease_benchmarking.af -V $variables -o $PROFILES_EXEC_PATH""_$GOLD -m 40gb -t 3-00:00:00 -n cal -c 2 -L $2
			AutoFlow -e -w $AUTOFLOW_TEMPLATES/phenotype_bench.af -V $variables -o $PROFILES_EXEC_PATH""_$GOLD -m 30gb -t 3-00:00:00 -n cal -c 2 -L $3
		done

elif [ "$2" == "prepare_results" ]; then
		for GOLD in $GOLD_STANDARDS; do prepare_type_of_record_counts.sh $GOLD; done #outputs to $RESULTS_PATH/number_of_records_$GOLD.txt
		get_pubmed_index_stats.py -d $RUN_TMP_PATH/abstracts_debug_stats.txt -o $PUBMED_FILES_STATS_PATH

elif [ "$2" == "reports" ]; then
		for GOLD in $GOLD_STANDARDS; do
			mkdir -p $RESULTS_PATH/reports/cohort_"$GOLD"_of_common_pmids_with_model; mkdir -p $RESULTS_PATH/reports/cohort_"$GOLD"_general
			echo "Getting $GOLD benchmark report"
			echo $GOLD > $TMP_PATH/gold_filename_prefix.txt
			data_paths=`echo -e "
				$TMP_PATH/HPO_terms_depth,
				$PUBMED_FILES_STATS_PATH/file_proportion_stats,
				$PUBMED_FILES_STATS_PATH/file_raw_stats,
				$PUBMED_FILES_STATS_PATH/total_proportion_stats,
				$PUBMED_FILES_STATS_PATH/total_stats,
				$RESULTS_PATH/pubmed_metadata,
				$RESULTS_PATH/llm_filtered_scores,
				$RESULTS_PATH/llm_vs_"$GOLD"_semantic_similarity_hpo_based.txt,
				$RESULTS_PATH/number_of_records_"$GOLD".txt,
				$RUN_INPUTS_PATH/"$GOLD"_HPOs_cleaned,
				$RUN_INPUTS_PATH/"$GOLD"_PMIDs_cleaned,			        
				$RESULTS_PATH/llm_pmID_profiles.txt,
				$TMP_PATH/gold_filename_prefix.txt
				" | tr -d [:space:]` 

			report_html -d $data_paths \
						-t $REPORTS_TEMPLATES/stEngine_and_similitudes.txt \
						-o $RESULTS_PATH/reports/stEngine_and_similitudes_$GOLD \
						-s $REPORTS_TEMPLATES/subtemplates

			#cohort_analyzer -i $RUN_INPUTS_PATH/"$GOLD"_HPOs_cleaned -o $RESULTS_PATH/reports/cohort_"$GOLD"_of_common_pmids_with_model/cohort_analyzer -d 0 -p 1 -S "," -m lin -a -H
			#cohort_analyzer -i $INPUTS_PATH/general_$GOLD"_hpo_profiles" -o $RESULTS_PATH/reports/cohort_"$GOLD"_general/cohort_analyzer -d 0 -p 1 -S "," -m lin -a -H
		done
		#cohort_analyzer -i $RESULTS_PATH/llm_pmID_profiles.txt -o $RESULTS_PATH/reports/cohort_stEngine/cohort_analyzer -d 0 -p 1 -S "," -m lin -a -H

elif [ "$2" == "prepare_metareport_data" ]; then 
		prepare_metareport.sh

elif [ "$2" == "metareport" ]; then
		HPO_PATH=`semtools -d list | grep HPO`
		MONDO_PATH=`semtools -d list | grep MONDO`

		echo -e "ONT_SIM_METHOD\t"$ONT_SIM_METHOD > $TMP_PATH/ont_sim_method_used

		data_paths=`echo -e "
			$METAREPORT_RESULTS_PATH/all_disease_data,
			$METAREPORT_RESULTS_PATH/all_phenotype_data,
			$INPUTS_PATH/omim_hpo_profiles.txt,
			$INPUTS_PATH/omim_pubmed_profiles.txt,
			$INPUTS_PATH/omim2_hpo_profiles.txt,
			$INPUTS_PATH/omim2_pubmed_profiles.txt,
			$METAREPORT_RESULTS_PATH/ehrhart_papers_llm_pmID_profiles.txt,
			$METAREPORT_RESULTS_PATH/ehrhart_abstracts_llm_pmID_profiles.txt,
			$METAREPORT_RESULTS_PATH/do_papers_llm_pmID_profiles.txt,
			$METAREPORT_RESULTS_PATH/do_abstracts_llm_pmID_profiles.txt,
			$QUERIES_PATH/omim_list,$METAREPORT_RESULTS_PATH/pmid_titles,
			$META_GS_COUNTS_FOLD_JOINED/phenotype_gs_counts,
			$META_GS_COUNTS_FOLD_JOINED/disease_gs_counts,
			$TMP_PATH/ont_sim_method_used
			" | tr -d [:space:]`

		create_metareport.py -d $data_paths \
							 -t $REPORTS_TEMPLATES/metareport.txt \
							 -a $REPORTS_TEMPLATES/subtemplates \
							 -o $METAREPORT_RESULTS_PATH/metareport \
							 -O $HPO_PATH \
							 -M $MONDO_PATH \
							 -R "(OMIM:[0-9]{6}|OMIMPS:[0-9]{6})"		

elif [ "$2" == "prepare_pubmed_stats" ]; then
		prepare_pubmed_stats.sh
elif [ "$2" == "pubmed_report" ]; then
		report_html -d $PUBMED_FOLD"/*" \
					-t $REPORTS_TEMPLATES/pubmed_stats.txt \
					-o $PUBMED_REPORT/pubmed_stats_$GS_TYPE 

elif [ "$2" == "raso_wf" ]; then #Proof of concept workflow with Rasopathies (Noonan, Costello, CFC and NF1 syndromes)
		source ~soft_bio_267/initializes/init_autoflow
		rm $RUN_TMP_PATH/diseases_to_proof

		#Change to proof_diseases.txt later prueba.txt 
		cat proof_diseases.txt | while read row; do #Get each OMIM ID and disease from the proof diseases and get their HPO profiles
			omim_id=`echo $row | awk 'BEGIN{FS=","}{print $1}'`
			disease=`echo $row | awk 'BEGIN{FS=","}{print $2}'`
			grep $omim_id $INPUTS_PATH/omim_hpo_profiles.txt | cut -f 2 | tr "," "\n" > $RUN_TMP_PATH/$disease.txt
			echo $RUN_TMP_PATH/$disease.txt >> $RUN_TMP_PATH/diseases_to_proof		
		done
		n_diseases=`wc -l $RUN_TMP_PATH/diseases_to_proof | cut -f 1 -d " "`
		
		variables=`echo -e "
						\\$pyenv=$PYENV,
						\\$code_path=$CODE_PATH,
						\\$results_path=$RESULTS_PATH,
						\\$top10_raso_folder=$TOP10_RASO_FOLDER,
						\\$proof_folder=$PROOF_FOLDER,
						\\$diseases_range_number=1-$n_diseases,
						\\$diseases_filepaths=$RUN_TMP_PATH/diseases_to_proof,
						\\$pubmed_ids_and_titles=$RESULTS_PATH/pubmed_ids_and_titles,
						\\$report_templates_path=$REPORTS_TEMPLATES,
						\\$ont_sim_method=$ONT_SIM_METHOD,
						\\$doctype_placeholder_var=$DOCTYPE_PLACEHOLDER_VAR,
						\\$document_type=$DOCUMENT_TYPE,
						" | tr -d [:space:]`
		
		AutoFlow -e -w $AUTOFLOW_TEMPLATES/rasopathies.af -V $variables -o $PROOF_EXEC_PATH -m 200gb -t 3-12:00:00 -n cal -c 1 -L $3

elif [ "$2" == "raso_heat" ]; then
		make_rasopathies_cluster_heatmap.sh

elif [ "$2" == "mermaid" ]; then
		report_html -d $INPUTS_PATH/omim_hpo_profiles.txt \
					-t $REPORTS_TEMPLATES/mermaid_icons.txt \
					-o $METAREPORT_RESULTS_PATH/reports/mermaid_workflows 

elif [ "$2" == "find_match" ]; then
		PMID=$3;HPO=$4
		find_matched_sentence.sh $RESULTS_PATH $PMID $HPO

elif [ "$2" == "copy_reports" ]; then
		mkdir -p $PAPER_REPORTS/rasopaties_heatmaps/abstracts; mkdir -p $PAPER_REPORTS/rasopaties_heatmaps/papers
		mkdir -p $PAPER_REPORTS/latex_tables/abstracts; mkdir -p $PAPER_REPORTS/latex_tables/papers
		#TOP50 HEATMAPS
		cp $CURRENT_PATH/runs/OMIM_ALL/splitabstract/results/proof_of_concept/*_improved_heat.html $PAPER_REPORTS/rasopaties_heatmaps/abstracts
		cp $CURRENT_PATH/runs/OMIM_ALL/splitpaper/results/proof_of_concept/*_improved_heat.html $PAPER_REPORTS/rasopaties_heatmaps/papers
		#TOP50 LATEX TABLES
		cp $CURRENT_PATH/runs/OMIM_ALL/splitabstract/results/proof_of_concept/*_top50_latex_table.txt $PAPER_REPORTS/latex_tables/abstracts
		cp $CURRENT_PATH/runs/OMIM_ALL/splitpaper/results/proof_of_concept/*_top50_latex_table.txt $PAPER_REPORTS/latex_tables/papers
		#METAREPORT
		cp $CURRENT_PATH/global_results/with_random_negatives/metareport/metareport.html $PAPER_REPORTS/metareport.html
		#PUBMED STATS
		cp $CURRENT_PATH/global_results/no_random_negatives/metareport/PUBMED_REPORT/pubmed_stats_OMIM_ALL.html $PAPER_REPORTS/pubmed_stats_OMIM_ALL.html
		#TOP10 CLUSTERMAP
		cp $CURRENT_PATH/runs/OMIM_ALL/splitpaper/results/proof_of_concept/top10_clustermap_and_table.html $PAPER_REPORTS/top10_clustermap_and_table.html
		#TOP10 LATEX TABLE
		cp $CURRENT_PATH/runs/OMIM_ALL/splitpaper/results/proof_of_concept/aggregated_top10_latex_table.txt $PAPER_REPORTS/latex_tables/aggregated_top10_latex_table.txt

elif [ `echo $2 | cut -f 2 -d "-"` == "check" ]; then 
		. ~soft_bio_267/initializes/init_autoflow
		path_to_check=$(grep -E ^`echo $2 | cut -f 1 -d "-"` $CURRENT_PATH/workflow_paths | cut -f 2)
		if [ $2 == "phen_bench_wf-check" ]; then
				for GOLD in $GOLD_STANDARDS; do
					echo "Checking logs of execution path: "$path_to_check'_'$GOLD
					flow_logger -w -e $path_to_check'_'$GOLD  -r all $ADD_OPTIONS
				done
		else
				echo "Checking logs of execution path: "$path_to_check
				flow_logger -w -e $path_to_check -r all $ADD_OPTIONS				
		fi

elif [ `echo $2 | cut -f 2 -d "-"` == "recover" ]; then 
		. ~soft_bio_267/initializes/init_autoflow
		path_to_recover=$(grep -E ^`echo $2 | cut -f 1 -d "-"` $CURRENT_PATH/workflow_paths | cut -f 2)
		#Make a call to AutoFlow -v if some step of the workflow failed and you want to change the template and dry run to change the sh before running the recover step
		if [ $2 == "phen_bench_wf-recover" ]; then
				for GOLD in $GOLD_STANDARDS; do
					echo "Recovering failed task of execution path: " $path_to_recover'_'$GOLD
					flow_logger -w -e $path_to_recover'_'$GOLD --sleep 0.1 -l -p $ADD_OPTIONS
				done
		else
				echo "Recovering failed task of execution path: $path_to_check"
				flow_logger -w -e $path_to_recover --sleep 0.1 -l -p $ADD_OPTIONS				
		fi
fi		