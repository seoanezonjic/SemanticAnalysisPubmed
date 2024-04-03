#! /usr/bin/env bash
. ~soft_bio_267/initializes/init_python

export CURRENT_PATH=`pwd`
export QUERIES_PATH=$CURRENT_PATH/queries
export RESULTS_PATH=$CURRENT_PATH/results
export PUBMED_PATH=/mnt2/fscratch/users/pab_001_uma/pedro/software_data/pubmed
export MODEL_PATH=$CURRENT_PATH/models
export MODEL_NAME="all-mpnet-base-v2"
#export MODEL_NAME="all-MiniLM-L6-v2"
export CURRENT_MODEL=$MODEL_PATH/$MODEL_NAME

export PYENV=$HOME/py_venvs/llm_env #TODO: Remove later
export CODE_PATH=$CURRENT_PATH/scripts #TODO: Remove later
export PUBMED_CHUNKSIZE=100000

mkdir $RESULTS_PATH

#PATHS TO EXECUTION OF TEMPLATES
export ENGINE_EXEC_PATH=$FSCRATCH/SemanticAnalysisPubmed/EXECS_engine
export PROFILES_EXEC_PATH=$FSCRATCH/SemanticAnalysisPubmed/EXECS_profiles

##BEGIN: EXPERIMENTAL: TRYING TO PARALLELIZE 3 PUBMED BALANCED-FILLED FOLDERS TO DRISTIBUTE THE EMBEDDING PROCESS IN 3 EXA NODES
export PARALLEL_FOLDERS_BASENAME="chunk"
export FOLDERS_TO_PARALLELIZE="${PARALLEL_FOLDERS_BASENAME}0;${PARALLEL_FOLDERS_BASENAME}1;${PARALLEL_FOLDERS_BASENAME}2" #;${PARALLEL_FOLDERS_BASENAME}3" temporally disabled because one exa node is down
export TSV_FOLDERS=`echo $FOLDERS_TO_PARALLELIZE | tr ";" "-"`
export PARALLEL_FOLDERS_ARRAY=(${FOLDERS_TO_PARALLELIZE//;/ })
export N_PARALLEL_FOLDERS=${#PARALLEL_FOLDERS_ARRAY[@]}
##END: EXPERIMENTAL

export GPU_DEVICES="cuda:0-cuda:1-cuda:2-cuda:3"

if [ "$1" == "download" ] ; then # DOWNLOAD MODEL
        mkdir -p $MODEL_PATH
        source $PYENV/bin/activate #TODO: Remove later
        stEngine -m $MODEL_NAME -p $CURRENT_MODEL 
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
                \\$min_similarity=0.5,
                \\$queries=$QUERIES_PATH/hpo_list,
                \\$pubmed_path=$PUBMED_PATH,
                \\$pyenv=$PYENV,
                \\$gpu_devices=$GPU_DEVICES,
                \\$parallel_folders_basename=$PARALLEL_FOLDERS_BASENAME,
                \\$folders_to_parallelize=$FOLDERS_TO_PARALLELIZE,
                \\$tsv_folder=$TSV_FOLDERS,
                \\$n_parallel_folders=$N_PARALLEL_FOLDERS,
                \\$pubmed_chunksize=$PUBMED_CHUNKSIZE,
                \\$results_path=$RESULTS_PATH       
            " | tr -d [:space:]`
        AutoFlow -e -w templates/workflow.af -V $variables -o $ENGINE_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -c 10 -L $2
elif [ "$1" == "engine_check" ]; then 
	. ~soft_bio_267/initializes/init_autoflow
        flow_logger -w -e $ENGINE_EXEC_PATH  -r all $ADD_OPTIONS
elif [ "$1" == "engine_recover" ]; then 
	. ~soft_bio_267/initializes/init_autoflow
        #Make a call to AutoFlow -v if some step of the workflow failed and you want to change the template and dry run to change the sh before running the recover step
        flow_logger -w -e $ENGINE_EXEC_PATH --sleep 0.1 -l -p $ADD_OPTIONS

elif [ "$1" == "profiles_wf" ]; then
        mkdir -p $PROFILES_EXEC_PATH
        source ~soft_bio_267/initializes/init_autoflow
        variables=`echo -e "
                \\$suggestions_template=$PWD/templates/reports/suggestions.txt,
                \\$results_path=$RESULTS_PATH,
                \\$code_path=$CODE_PATH,
                \\$pubmed_profiles=$RESULTS_PATH/pmID_profiles.txt
                " | tr -d [:space:]`
        AutoFlow -e -w templates/profile_analysis.af -V $variables -o $PROFILES_EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -L $2
fi