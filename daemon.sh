#! /usr/bin/env bash
. ~soft_bio_267/initializes/init_python

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
export CODE_PATH=$CURRENT_PATH/scripts #TODO: Remove later
export TMP_PATH=$CURRENT_PATH/tmp
export INPUTS_PATH=$CURRENT_PATH/inputs

mkdir $RESULTS_PATH; mkdir $RESULTS_PATH/reports; mkdir $INPUTS_PATH ; mkdir $TMP_PATH
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
export MIN_SIMILARITY=0.85
#export GPU_DEVICES="cuda:0-cuda:1-cuda:2-cuda:3"
export GPU_DEVICES="cuda:0-cuda:1-cuda:2-cuda:3-cuda:4-cuda:5-cuda:6-cuda:7"
export database_ids="OMIM ORPHA"



if [ "$1" == "download" ] ; then # DOWNLOAD MODEL and other resources
        #Download model
        mkdir -p $MODEL_PATH
        source $PYENV/bin/activate #TODO: Remove later
        stEngine -m $MODEL_NAME -p $CURRENT_MODEL

        #Download MONDO-PUMBED relations and MONDO-HP relations
        wget https://data.monarchinitiative.org/latest/tsv/all_associations/publication_disease.all.tsv.gz -O $TMP_PATH/publication_disease.all.tsv.gz
        wget http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa -O $TMP_PATH/phenotype.hpoa

        #Process MONDO-PUMBED relations
        zcat tmp/publication_disease.all.tsv.gz | tail -n +2 | cut -f 1,5 | grep MONDO | aggregate_column_data -i - -x 2 -a 1 > $INPUTS_PATH/mondo_pubmed_profiles.txt
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
                \\$report_templates_path=$CURRENT_PATH/templates/reports       
            " | tr -d [:space:]`
        AutoFlow -e -w templates/workflow.af -V $variables -o $ENGINE_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -c 10 -L $2
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

elif [ "$1" == "bench_wf" ]; then
        mkdir -p $PROFILES_EXEC_PATH
        source ~soft_bio_267/initializes/init_autoflow

        cut -f 1,2 $RESULTS_PATH/pmID_profiles.txt > $RESULTS_PATH/pmID_profiles_without_cosine_sim.txt

        RECORDS_NUMBER=`wc -l $INPUTS_PATH/mondo_hpo_profiles.txt | cut -f 1 -d " "`
        PACKAGE_SIZE=500
        PACKAGE_NUMBER=`echo "$RECORDS_NUMBER / $PACKAGE_SIZE" | bc`

        variables=`echo -e "
                \\$pyenv=$PYENV,
                \\$results_path=$RESULTS_PATH,
                \\$code_path=$CODE_PATH,
                \\$mondo_pubmed_profiles=$INPUTS_PATH/mondo_pubmed_profiles.txt,
                \\$mondo_hpo_profiles=$INPUTS_PATH/mondo_hpo_profiles.txt,
                \\$llm_pmID_profiles=$RESULTS_PATH/pmID_profiles_without_cosine_sim.txt,
                \\$package_number="0-$PACKAGE_NUMBER",
                \\$package_size=$PACKAGE_SIZE
                " | tr -d [:space:]`
        AutoFlow -e -w templates/disease_benchmarking.af -V $variables -o $PROFILES_EXEC_PATH -m 4gb -t 3-00:00:00 -n cal -c 2 -L $2
fi