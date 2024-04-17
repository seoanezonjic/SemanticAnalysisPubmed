#! /usr/bin/env bash
source ~soft_bio_267/initializes/init_python

#PATHS
export CURRENT_PATH=`pwd`
export QUERIES_PATH=$CURRENT_PATH/queries
export RESULTS_PATH=$CURRENT_PATH/results
export PUBMED_PATH=/mnt2/fscratch/users/pab_001_uma/pedro/software_data/pubmed
export MODEL_PATH=$CURRENT_PATH/models
export MODEL_NAME="all-mpnet-base-v2"
export CURRENT_MODEL=$MODEL_PATH/$MODEL_NAME
#export MODEL_NAME="all-MiniLM-L6-v2"

export PYENV=$HOME/py_venvs/llm_env #TODO: Remove later
export CODE_PATH=$CURRENT_PATH/scripts
export TMP_PATH=$CURRENT_PATH/tmp
export INPUTS_PATH=$CURRENT_PATH/inputs

export TEMPLATES_PATH=$CURRENT_PATH/templates
export AUTOFLOW_TEMPLATES=$TEMPLATES_PATH/autoflow
export REPORTS_TEMPLATES=$TEMPLATES_PATH/reports

mkdir $RESULTS_PATH; mkdir $RESULTS_PATH/reports; mkdir $INPUTS_PATH ; mkdir $TMP_PATH; mkdir $TEMPLATES_PATH; mkdir $AUTOFLOW_TEMPLATES; mkdir $REPORTS_TEMPLATES; mkdir $QUERIES_PATH
export PATH=$CODE_PATH:$PATH

#PATHS TO EXECUTION OF TEMPLATES
export ENGINE_EXEC_PATH=$FSCRATCH/SemanticAnalysisPubmed/EXECS_engine
export PROFILES_EXEC_PATH=$FSCRATCH/SemanticAnalysisPubmed/EXECS_profiles
echo -e "engine_wf\t$ENGINE_EXEC_PATH" > $CURRENT_PATH/workflow_paths
echo -e "bench_wf\t$PROFILES_EXEC_PATH" >> $CURRENT_PATH/workflow_paths

##BEGIN: EXPERIMENTAL: TRYING TO PARALLELIZE 4 PUBMED BALANCED-FILLED FOLDERS TO DRISTIBUTE THE EMBEDDING PROCESS IN THE 4 EXA NODES (EACH ONE USING 4 GPUS with embedd_multiprocess)
export PARALLEL_FOLDERS_BASENAME="chunk"
export FOLDERS_TO_PARALLELIZE="${PARALLEL_FOLDERS_BASENAME}0;${PARALLEL_FOLDERS_BASENAME}1;${PARALLEL_FOLDERS_BASENAME}2;${PARALLEL_FOLDERS_BASENAME}3"
export TSV_FOLDERS=`echo $FOLDERS_TO_PARALLELIZE | tr ";" "-"`
export PARALLEL_FOLDERS_ARRAY=(${FOLDERS_TO_PARALLELIZE//;/ })
export N_PARALLEL_FOLDERS=${#PARALLEL_FOLDERS_ARRAY[@]}
##END: EXPERIMENTAL

#OTHER VARIABLES
export PUBMED_CHUNKSIZE=300000
export MIN_SIMILARITY=0.7
export TOP_K=200
#export GPU_DEVICES="cuda:0-cuda:1-cuda:2-cuda:3"
export GPU_DEVICES="cuda:0-cuda:1-cuda:2-cuda:3-cuda:4-cuda:5-cuda:6-cuda:7"
export database_ids="OMIM ORPHA"



if [ "$1" == "download" ] ; then # DOWNLOAD MODEL and other resources
        #Download model
        mkdir -p $MODEL_PATH
        source $PYENV/bin/activate #TODO: Remove later
        stEngine -m $MODEL_NAME -p $CURRENT_MODEL -v

        #Download MONDO-PUMBED relations and MONDO-HP relations
        wget https://data.monarchinitiative.org/latest/tsv/all_associations/publication_disease.all.tsv.gz -O $TMP_PATH/publication_disease.all.tsv.gz
        wget http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa -O $TMP_PATH/phenotype.hpoa

        #Process MONDO-PUMBED relations
        zcat tmp/publication_disease.all.tsv.gz | tail -n +2 | cut -f 1,5 | grep MONDO | grep PMID | sed "s/PMID://g" | \
                aggregate_column_data -i - -x 2 -a 1 > $INPUTS_PATH/mondo_pubmed_profiles.txt
        #Process MONDO-HP relations
        prepare_mondo_hp_relations.sh

elif [ "$1" == "queries" ] ; then
        mkdir -p $QUERIES_PATH
	semtools -O HPO -C CNS/HP:0000118 > $QUERIES_PATH/hpo_list

elif [ "$1" == "engine_wf" ] ; then
        mkdir -p $ENGINE_EXEC_PATH
        source ~soft_bio_267/initializes/init_autoflow
        variables=`echo -e "
                \\$code_path=$CODE_PATH,
                \\$model_name=$MODEL_NAME,
        	\\$current_model=$CURRENT_MODEL,
                \\$min_similarity=$MIN_SIMILARITY,
                \\$top_k=$TOP_K,
                \\$queries=$QUERIES_PATH/hpo_list,
                \\$pubmed_path=$PUBMED_PATH,
                \\$pyenv=$PYENV,
                \\$gpu_devices=$GPU_DEVICES,
                \\$parallel_folders_basename=$PARALLEL_FOLDERS_BASENAME,
                \\$folders_to_parallelize=$FOLDERS_TO_PARALLELIZE,
                \\$tsv_folder=$TSV_FOLDERS,
                \\$n_parallel_folders=$N_PARALLEL_FOLDERS,
                \\$pubmed_chunksize=$PUBMED_CHUNKSIZE,
                \\$results_path=$RESULTS_PATH,
                \\$tmp_path=$TMP_PATH,
                \\$report_templates_path=$REPORTS_TEMPLATES       
            " | tr -d [:space:]`
        AutoFlow -e -w $AUTOFLOW_TEMPLATES/workflow.af -V $variables -o $ENGINE_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -c 10 -L $2

elif [ "$1" == "bench_wf" ]; then
        mkdir -p $PROFILES_EXEC_PATH
        source ~soft_bio_267/initializes/init_autoflow
        source $PYENV/bin/activate #TODO: Remove later
        cut -f 1,2 $RESULTS_PATH/llm_pmID_profiles_with_cosine_sim.txt > $RESULTS_PATH/llm_pmID_profiles.txt

        #Get LLM and MONDO common pmIDs
        desaggregate_column_data -i $INPUTS_PATH/mondo_pubmed_profiles.txt -x 2 | aggregate_column_data -i - -x 2 -a 1 > $TMP_PATH/reverse_aggregated_mondo_pmid_profiles.txt
        intersect_columns -a $TMP_PATH/reverse_aggregated_mondo_pmid_profiles.txt -b $RESULTS_PATH/llm_pmID_profiles.txt -A 1 -B 1 --k c --full |\
                cut -f 1,2 | desaggregate_column_data -i - -x 2 | aggregate_column_data -i - -x 2 -a 1 | sort -u > $INPUTS_PATH/mondo_pubmed_profiles_common_pmids.txt

        #Get MONDO IDs with both HPO and pmID profiles
        intersect_columns -a $INPUTS_PATH/mondo_pubmed_profiles_common_pmids.txt -b $INPUTS_PATH/mondo_hpo_profiles.txt -A 1 -B 1 --k c --full > $TMP_PATH/mondo_pmids_and_hpos 
        cut -f 1,2 $TMP_PATH/mondo_pmids_and_hpos | sort -u > $INPUTS_PATH/MONDO_PMIDs_cleaned
        cut -f 3,4 $TMP_PATH/mondo_pmids_and_hpos | sort -u > $INPUTS_PATH/MONDO_HPOs_cleaned
        cut -f 1 $TMP_PATH/mondo_pmids_and_hpos > $TMP_PATH/mondo_PMID_HPO_common_IDs

        #Get the number of records to process and the package size
        RECORDS_NUMBER=`wc -l $TMP_PATH/mondo_PMID_HPO_common_IDs | cut -f 1 -d " "`
        PACKAGE_SIZE=50
        PACKAGE_NUMBER=`echo "$RECORDS_NUMBER / $PACKAGE_SIZE" | bc`

        variables=`echo -e "
                \\$pyenv=$PYENV,
                \\$results_path=$RESULTS_PATH,
                \\$code_path=$CODE_PATH,
                \\$mondo_pmid_hpo_common_ids=$TMP_PATH/mondo_PMID_HPO_common_IDs,
                \\$mondo_pmID_profiles=$INPUTS_PATH/MONDO_PMIDs_cleaned,
                \\$mondo_hpo_profiles=$INPUTS_PATH/MONDO_HPOs_cleaned,
                \\$llm_pmID_profiles=$RESULTS_PATH/llm_pmID_profiles.txt,
                \\$package_number="0-$PACKAGE_NUMBER",
                \\$package_size=$PACKAGE_SIZE,
                \\$report_templates_path=$REPORTS_TEMPLATES
                " | tr -d [:space:]`
        AutoFlow -e -w $AUTOFLOW_TEMPLATES/disease_benchmarking.af -V $variables -o $PROFILES_EXEC_PATH -m 4gb -t 3-00:00:00 -n cal -c 2 -L $2

elif [ "$1" == "reports" ]; then
        #Preparing some data for benchmarking part
        prepare_type_of_record_counts.sh

        #stEngine reports
        pmd_idx_stats=$RESULTS_PATH/abstracts_stats_tables
        get_pubmed_index_stats.py -d $TMP_PATH/abstracts_debug_stats.txt -o $pmd_idx_stats
        report_html -d $pmd_idx_stats/file_proportion_stats,$pmd_idx_stats/file_raw_stats,$pmd_idx_stats/total_proportion_stats,$pmd_idx_stats/total_stats \
                    -t $REPORTS_TEMPLATES/debug_report_get_pubmed_index.txt \
                    -o $RESULTS_PATH/reports/debug_report_get_pubmed_index

        report_html -d $RESULTS_PATH/llm_filtered_scores \
                    -t $REPORTS_TEMPLATES/debug_report_semantic_scores_stats.txt \
                    -o $RESULTS_PATH/reports/debug_report_semantic_scores_stats

        #Benchmark reports
        report_html -t $REPORTS_TEMPLATES/llm_mondo_similitudes.txt \
                    -d $RESULTS_PATH/llm_vs_mondo_semantic_similarity_hpo_based.txt,$RESULTS_PATH/number_of_records.txt \
                    -o $RESULTS_PATH/reports/llm_vs_mondo_similitudes

elif [ `echo $1 | cut -f 2 -d "_"` == "check" ]; then 
	. ~soft_bio_267/initializes/init_autoflow
        path_to_check=$(grep `echo $1 | cut -f 1 -d "_"` $CURRENT_PATH/workflow_paths | cut -f 2)
        echo $path_to_check
        flow_logger -w -e $path_to_check  -r all $ADD_OPTIONS

elif [ `echo $1 | cut -f 2 -d "_"` == "recover" ]; then 
	. ~soft_bio_267/initializes/init_autoflow
        path_to_recover=$(grep `echo $1 | cut -f 1 -d "_"` $CURRENT_PATH/workflow_paths | cut -f 2)
        #Make a call to AutoFlow -v if some step of the workflow failed and you want to change the template and dry run to change the sh before running the recover step
        flow_logger -w -e $path_to_recover --sleep 0.1 -l -p $ADD_OPTIONS
fi