#! /usr/bin/env bash
. ~soft_bio_267/initializes/init_python

export CURRENT_PATH=`pwd`
export EXEC_PATH=$FSCRATCH/SemanticAnalysisPubmed/EXECS
export QUERIES_PATH=$CURRENT_PATH/queries
export PUBMED_PATH=/mnt2/fscratch/users/pab_001_uma/pedro/software_data/pubmed
export MODEL_PATH=$CURRENT_PATH/models
export MODEL_NAME="all-mpnet-base-v2"
#export MODEL_NAME="all-MiniLM-L6-v2"
export CURRENT_MODEL=$MODEL_PATH/$MODEL_NAME

export PYENV=$HOME/py_venvs/llm_env

export CODE_PATH=$CURRENT_PATH/scripts #TODO: Remove later

export PUBMED_CHUNKSIZE=200000

##BEGIN: EXPERIMENTAL: TRYING TO PARALLELIZE 3 PUMBED FILLED BALANCED FOLDERS TO DRISTIBUTE THE EMBEDDING PROCESS IN 3 EXA NODES

export PARALLEL_FOLDERS_BASENAME="chunk"
#export FOLDERS_TO_PARALLELIZE="${PARALLEL_FOLDERS_BASENAME}0;${PARALLEL_FOLDERS_BASENAME}1;${PARALLEL_FOLDERS_BASENAME}2;${PARALLEL_FOLDERS_BASENAME}3"
export FOLDERS_TO_PARALLELIZE="${PARALLEL_FOLDERS_BASENAME}0;${PARALLEL_FOLDERS_BASENAME}1;${PARALLEL_FOLDERS_BASENAME}2"
export TSV_FOLDERS=`echo $FOLDERS_TO_PARALLELIZE | tr ";" "-"`
PARALLEL_FOLDERS_ARRAY=(${FOLDERS_TO_PARALLELIZE//;/ })
N_PARALLEL_FOLDERS=${#PARALLEL_FOLDERS_ARRAY[@]}

##END: EXPERIMENTAL

if [ "$1" == "download" ] ; then # DOWNLOAD MODEL
        mkdir -p $MODEL_PATH
        source $PYENV/bin/activate #TODO: Remove later
        stEngine -m $MODEL_NAME -p $CURRENT_MODEL 
elif [ "$1" == "queries" ] ; then
        mkdir -p $QUERIES_PATH
	semtools -O HPO -C CNS/HP:0000118 > $QUERIES_PATH/hpo_list
elif [ "$1" == "engine" ] ; then
        mkdir -p $EXEC_PATH
        source ~soft_bio_267/initializes/init_autoflow
        variables=`echo -e "
                \\$code_path=$CODE_PATH,
                \\$model_name=$MODEL_NAME,
        	\\$current_model=$CURRENT_MODEL,
                \\$min_similarity=0.5,
                \\$queries=$QUERIES_PATH/hpo_list,
                \\$pubmed_path=$PUBMED_PATH,
                \\$pyenv=$PYENV,
                \\$parallel_folders_basename=$PARALLEL_FOLDERS_BASENAME,
                \\$folders_to_parallelize=$FOLDERS_TO_PARALLELIZE,
                \\$tsv_folder=$TSV_FOLDERS,
                \\$n_parallel_folders=$N_PARALLEL_FOLDERS,
                \\$pubmed_chunksize=$PUBMED_CHUNKSIZE        
            " | tr -d [:space:]`
        AutoFlow -e -w templates/workflow.af -V $variables -o $EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -L $2
elif [ "$1" == "check" ]; then 
	. ~soft_bio_267/initializes/init_autoflow
        flow_logger -w -e $EXEC_PATH  -r all $ADD_OPTIONS

elif [ "$1" == "recover" ]; then 
	. ~soft_bio_267/initializes/init_autoflow
        #Make a call to AutoFlow -v if some step of the workflow failed and you want to change the template and dry run to change the sh before running the recover step
        flow_logger -w -e $EXEC_PATH --sleep 0.1 -l -p $ADD_OPTIONS
fi