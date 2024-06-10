#! /usr/bin/env bash
source ~soft_bio_267/initializes/init_python


############# GENERAL PATHS
export CURRENT_PATH=`pwd`
export INPUTS_PATH=$CURRENT_PATH/inputs
export QUERIES_PATH=$CURRENT_PATH/queries
export TMP_PATH=$CURRENT_PATH/tmp
export CODE_PATH=$CURRENT_PATH/scripts
export TEMPLATES_PATH=$CURRENT_PATH/templates
export AUTOFLOW_TEMPLATES=$TEMPLATES_PATH/autoflow
export REPORTS_TEMPLATES=$TEMPLATES_PATH/reports

export MODEL_PATH=$CURRENT_PATH/models
export MODEL_NAME="all-mpnet-base-v2" #export MODEL_NAME="all-MiniLM-L6-v2"
export CURRENT_MODEL=$MODEL_PATH/$MODEL_NAME 

export OMIM_QUERY_INPUT_DATA="/mnt/home/users/bio_267_uma/federogc/projects/GraphPrioritizer/control_genes/zampieri/data/omim_data/mimTitles.txt" #For OMIM list as query

export PYENV=$HOME/py_venvs/llm_env #TODO: Remove later
export PATH=$CODE_PATH:$PATH

################### RUN SPECIFIC PATHS
source $1
echo "DOING $RUN_NAME RUN"

export RUN_FOLDER=$CURRENT_PATH"/runs/"$RUN_NAME
export RUN_INPUTS_PATH=$RUN_FOLDER/"inputs"
export RUN_TMP_PATH=$RUN_FOLDER/"tmp"
export RESULTS_PATH=$RUN_FOLDER/"results"
export PUBMED_FILES_STATS_PATH=$RESULTS_PATH/abstracts_stats_tables

#PATHS TO EXECUTION OF TEMPLATES
export ENGINE_AUTOFLOW_TEMPLATE_PATH=$AUTOFLOW_TEMPLATES/$ENGINE_AUTOFLOW_TEMPLATE
export ZEROBENCH_EXEC_PATH=$FSCRATCH"/SemanticAnalysisPubmed/$RUN_NAME/EXECS_zerobench"
export ENGINE_EXEC_PATH=$FSCRATCH"/SemanticAnalysisPubmed/$RUN_NAME/EXECS_engine"
export PROFILES_EXEC_PATH=$FSCRATCH"/SemanticAnalysisPubmed/$RUN_NAME/EXECS_profiles"
echo -e "engine_wf\t$ENGINE_EXEC_PATH" > $CURRENT_PATH/workflow_paths
echo -e "bench_wf\t$PROFILES_EXEC_PATH" >> $CURRENT_PATH/workflow_paths
echo -e "zerobench_wf\t$ZEROBENCH_EXEC_PATH" >> $CURRENT_PATH/workflow_paths

mkdir -p $ENGINE_EXEC_PATH; mkdir -p $PROFILES_EXEC_PATH
mkdir -p $RESULTS_PATH; mkdir -p $RESULTS_PATH/reports; mkdir -p $INPUTS_PATH ; mkdir -p $TMP_PATH; mkdir -p $PUBMED_FILES_STATS_PATH; mkdir -p $RUN_INPUTS_PATH
mkdir -p $AUTOFLOW_TEMPLATES; mkdir -p $REPORTS_TEMPLATES; mkdir -p $QUERIES_PATH ; mkdir -p $TEMPLATES_PATH; mkdir -p $RUN_FOLDER; mkdir -p $RUN_TMP_PATH
#OTHER VARIABLES
export database_ids="OMIM ORPHA"


if [ "$2" == "goldstandard" ]; then #DOWNLOAD AND PREPARE GOLD STANDARDS TO ASSESS MODEL PERFORMANCE
#GS1	######### PREPARING MONDO-PMIDs AND MONDO-HPOs profiles ########
		#Download MONDO-PUMBED relations and MONDO-HP relations
		wget https://data.monarchinitiative.org/latest/tsv/all_associations/publication_disease.all.tsv.gz -O $TMP_PATH/publication_disease.all.tsv.gz
		wget http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa -O $TMP_PATH/phenotype.hpoa

		#Process MONDO-PUMBED relations
		zcat tmp/publication_disease.all.tsv.gz | tail -n +2 | cut -f 1,5,13 | grep MONDO | grep PMID | grep direct | cut -f 1,2 | sed "s/PMID://g" | \
				aggregate_column_data -i - -x 2 -a 1 > $INPUTS_PATH/mondo_pubmed_profiles.txt
		
		#Process MONDO-HP and OMIM-HP relations
		prepare_mondo_hp_relations.sh #Outpus to $INPUTS_PATH/mondo_hpo_profiles.txt and $INPUTS_PATH/omim_hpo_profiles.txt

#GS2	######## PREPARING OMIM-PMIDs AND OMIM-HPOs profiles FROM DOID #######
		semtools -O DO --return_all_terms_with_user_defined_attributes 'id,def,xref' |  grep "OMIM" | grep "pubmed" > $TMP_PATH/DOID_raw_data
		get_required_fields_from_DO_goldstandard.py -i $TMP_PATH/DOID_raw_data -o $INPUTS_PATH/omim_pubmed_profiles.txt
		#alredady produced $INPUTS_PATH/omim_hpo_profiles.txt with prepare_mondo_hp_relations.sh script

#GS3	######## PREPARING OMIM-PMIDs AND OMIM-HPOs profiles from the paper found by PSZ  ####### https://pubmed.ncbi.nlm.nih.gov/33947870/
		wget https://figshare.com/ndownloader/files/25769330 -O $TMP_PATH/omim2.txt
		tail -n +2 $TMP_PATH/omim2.txt | awk 'BEGIN{IFS="\t";OFS="\t"}{print "OMIM:"$4,$3}' | \
				aggregate_column_data -i - -x 1 -a 2 > $INPUTS_PATH/omim2_pubmed_profiles.txt		
		ln -s $INPUTS_PATH/omim_hpo_profiles.txt $INPUTS_PATH/omim2_hpo_profiles.txt
		
		#### Downloads PMC-PMID equivalences for some full papers that does not have PMID field
		wget https://ftp.ncbi.nlm.nih.gov/pub/pmc/PMC-ids.csv.gz -O $TMP_PATH/PMC-ids.csv.gz
		zcat $TMP_PATH/PMC-ids.csv.gz | cut -d "," -f 9,10 | tail -n +2 | tr "," "\t" | awk '{ if(NF == 2) print $0}' > $INPUTS_PATH/PMC-PMID_equivalencies

elif [ "$2" == "download" ] ; then # DOWNLOAD MODEL
		#Download model
		mkdir -p $MODEL_PATH
		source $PYENV/bin/activate #TODO: Remove later
		stEngine -m $MODEL_NAME -p $CURRENT_MODEL -v

elif [ "$2" == "queries" ] ; then
		mkdir -p $QUERIES_PATH
		
		#PREPARING HPO QUERY
		semtools -O HPO -C CNS/HP:0000118 > $QUERIES_PATH/hpo_list
		semtools --list_term_attributes -O HPO -S "," | awk '{FS="\t";OFS="\t"}{print $1,$2,$3-1}' | cut -f 1,3 > $TMP_PATH/HPO_terms_depth

		#PREPARING OMIM QUERY
		grep -P "Number Sign|Percent" $OMIM_QUERY_INPUT_DATA | grep -v "#" | cut -f 2,3 | cut -d ";" -f 1 | sed -E "s/([0-6][0-9]{5})/OMIM:\1/g" > $QUERIES_PATH/omim_list

elif [ "$2" == "zerobench_wf" ] ; then
		source ~soft_bio_267/initializes/init_autoflow
		variables=`echo -e "
			\\$code_path=$CODE_PATH,
			\\$model_name=$MODEL_NAME,
			\\$current_model=$CURRENT_MODEL,
			\\$splitted=$SPLITTED,
			\\$paper=$PAPER,
			\\$equivalences=$EQUIVALENCES,
			\\$queries=$QUERIES_PATH/hpo_list,
			\\$pubmed_path=$CORPUS_PATH,
			\\$pyenv=$PYENV,
			\\$gpu_devices=$GPU_DEVICES,
			\\$n_gpus=$N_GPUs,
			\\$use_gpu_for_sim_calc=$USE_GPU_FOR_SIM_CALC,
			\\$parallel_folders_basename=$PARALLEL_FOLDERS_BASENAME,
			\\$folders_to_parallelize=$FOLDERS_TO_PARALLELIZE,
			\\$tsv_folder=$TSV_FOLDERS,
			\\$n_parallel_folders=$N_PARALLEL_FOLDERS,
			\\$pubmed_chunksize=$PUBMED_CHUNKSIZE,
			\\$results_path=$RESULTS_PATH,
			\\$report_templates_path=$REPORTS_TEMPLATES,
			\\$omim=$INPUTS_PATH"/omim_pubmed_profiles.txt",
			\\$omim2=$INPUTS_PATH"/omim2_pubmed_profiles.txt"			       
			" | tr -d [:space:]`
		AutoFlow -e -w $AUTOFLOW_TEMPLATES/zero_bench.af -V $variables -o $ENGINE_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -c 10 -L $3

elif [ "$2" == "engine_wf" ] ; then
		source ~soft_bio_267/initializes/init_autoflow
		variables=`echo -e "
			\\$code_path=$CODE_PATH,
			\\$model_name=$MODEL_NAME,
			\\$current_model=$CURRENT_MODEL,
			\\$soft_min_similarity=$SOFT_MIN_SIMILARITY,
			\\$hard_min_similarity=$HARD_MIN_SIMILARITY,
			\\$top_k=$TOP_K,
			\\$splitted=$SPLITTED,
			\\$paper=$PAPER,
			\\$equivalences=$EQUIVALENCES,
			\\$queries=$QUERIES_PATH/hpo_list,
			\\$pubmed_path=$CORPUS_PATH,
			\\$pyenv=$PYENV,
			\\$gpu_devices=$GPU_DEVICES,
			\\$n_gpus=$N_GPUs,
			\\$use_gpu_for_sim_calc=$USE_GPU_FOR_SIM_CALC,
			\\$parallel_folders_basename=$PARALLEL_FOLDERS_BASENAME,
			\\$folders_to_parallelize=$FOLDERS_TO_PARALLELIZE,
			\\$tsv_folder=$TSV_FOLDERS,
			\\$n_parallel_folders=$N_PARALLEL_FOLDERS,
			\\$pubmed_chunksize=$PUBMED_CHUNKSIZE,
			\\$results_path=$RESULTS_PATH,
			\\$tmp_path=$RUN_TMP_PATH,
			\\$report_templates_path=$REPORTS_TEMPLATES,
			\\$omim=$INPUTS_PATH"/omim_pubmed_profiles.txt",
			\\$omim2=$INPUTS_PATH"/omim2_pubmed_profiles.txt"			       
			" | tr -d [:space:]`
		AutoFlow -e -w $ENGINE_AUTOFLOW_TEMPLATE_PATH -V $variables -o $ENGINE_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -c 10 -L $3

elif [ "$2" == "prepare_bench" ]; then
		for GOLD in $GOLD_STANDARDS; do
			#Get LLM and MONDO|OMIM common pmIDs
			desaggregate_column_data -i $INPUTS_PATH/$GOLD"_pubmed_profiles.txt" -x 2 | aggregate_column_data -i - -x 2 -a 1 > $RUN_TMP_PATH/reverse_aggregated_$GOLD"_pmid_profiles.txt"
			intersect_columns -a $RUN_TMP_PATH/reverse_aggregated_$GOLD"_pmid_profiles.txt" -b $RESULTS_PATH/llm_pmID_profiles.txt -A 1 -B 1 --k c --full |\
							cut -f 1,2 | desaggregate_column_data -i - -x 2 | aggregate_column_data -i - -x 2 -a 1 | sort -u > $RUN_TMP_PATH/$GOLD"_pubmed_profiles_common_pmids.txt"

			#Get MONDO|OMIM IDs with both HPO and pmID profiles
			intersect_columns -a $RUN_TMP_PATH/$GOLD"_pubmed_profiles_common_pmids.txt" -b $INPUTS_PATH/$GOLD"_hpo_profiles.txt" -A 1 -B 1 --k c --full > $RUN_TMP_PATH/$GOLD"_pmids_and_hpos" 
			cut -f 1,2 $RUN_TMP_PATH/$GOLD"_pmids_and_hpos" | sort -u > $RUN_INPUTS_PATH/$GOLD"_PMIDs_cleaned"
			cut -f 3,4 $RUN_TMP_PATH/$GOLD"_pmids_and_hpos" | sort -u > $RUN_INPUTS_PATH/$GOLD"_HPOs_cleaned"
			cut -f 1 $RUN_TMP_PATH/$GOLD'_pmids_and_hpos' > $RUN_TMP_PATH/$GOLD'_PMID_HPO_common_IDs'
		done

elif [ "$2" == "bench_wf" ]; then
		source ~soft_bio_267/initializes/init_autoflow
		source $PYENV/bin/activate #TODO: Remove later

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
						\\$gold=$GOLD
						" | tr -d [:space:]`
			#AutoFlow -e -w $AUTOFLOW_TEMPLATES/disease_benchmarking.af -V $variables -o $PROFILES_EXEC_PATH""_$GOLD -m 40gb -t 3-00:00:00 -n cal -c 2 -L $2
			AutoFlow -e -w $AUTOFLOW_TEMPLATES/disease_benchmarking.af -V $variables -o $PROFILES_EXEC_PATH""_$GOLD -m 30gb -t 3-00:00:00 -n cal -c 2 -L $3
		done

elif [ "$2" == "prepare_results" ]; then
		source $PYENV/bin/activate #TODO: Remove later
		for GOLD in $GOLD_STANDARDS; do prepare_type_of_record_counts.sh $GOLD; done #outputs to $RESULTS_PATH/number_of_records_$GOLD.txt
		get_pubmed_index_stats.py -d $RUN_TMP_PATH/abstracts_debug_stats.txt -o $PUBMED_FILES_STATS_PATH

elif [ "$2" == "reports" ]; then
		#Preparing some data for benchmarking part
		source $PYENV/bin/activate #TODO: Remove later

		for GOLD in $GOLD_STANDARDS; do
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
						-o $RESULTS_PATH/reports/stEngine_and_similitudes_$GOLD
		done

elif [ `echo $2 | cut -f 2 -d "_"` == "check" ]; then 
		. ~soft_bio_267/initializes/init_autoflow
		path_to_check=$(grep -E ^`echo $2 | cut -f 1 -d "_"` $CURRENT_PATH/workflow_paths | cut -f 2)
		if [ $2 == "bench_check" ]; then
				for GOLD in $GOLD_STANDARDS; do
					echo "Checking logs of execution path: "$path_to_check'_'$GOLD
					flow_logger -w -e $path_to_check'_'$GOLD  -r all $ADD_OPTIONS
				done
		else
				echo "Checking logs of execution path: "$path_to_check
				flow_logger -w -e $path_to_check -r all $ADD_OPTIONS				
		fi

elif [ `echo $2 | cut -f 2 -d "_"` == "recover" ]; then 
		. ~soft_bio_267/initializes/init_autoflow
		path_to_recover=$(grep -E ^`echo $2 | cut -f 1 -d "_"` $CURRENT_PATH/workflow_paths | cut -f 2)
		#Make a call to AutoFlow -v if some step of the workflow failed and you want to change the template and dry run to change the sh before running the recover step
		if [ $2 == "bench_recover" ]; then
				for GOLD in $GOLD_STANDARDS; do
					echo "Recovering failed task of execution path: " $path_to_recover'_'$GOLD
					flow_logger -w -e $path_to_recover'_'$GOLD --sleep 0.1 -l -p $ADD_OPTIONS
				done
		else
				echo "Recovering failed task of execution path: $path_to_check"
				flow_logger -w -e $path_to_recover --sleep 0.1 -l -p $ADD_OPTIONS				
		fi		
fi
