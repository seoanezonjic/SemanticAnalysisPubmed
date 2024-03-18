#! /usr/bin/env bash
. ~soft_bio_267/initializes/init_python

export CURRENT_PATH=`pwd`
export EXEC_PATH=$FSCRATCH/SemanticAnalysisPubmed/EXECS
export QUERIES_PATH=$CURRENT_PATH/queries
export PUBMED_PATH=/mnt2/fscratch/users/pab_001_uma/pedro/software_data/pubmed
export MODEL_PATH=$CURRENT_PATH/models
#export MODEL_NAME="all-mpnet-base-v2"
export MODEL_NAME="all-MiniLM-L6-v2"
export CURRENT_MODEL=$MODEL_PATH/$MODEL_NAME

export PYENV=$HOME/py_venvs/llm_env
export PYENV_GPU=$HOME/py_venvs/llm_gpu_env

export CODE_PATH=$CURRENT_PATH/scripts #TODO: Remove later

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
                \\$pyenv_gpu=$PYENV_GPU        
            " | tr -d [:space:]`
        AutoFlow -e -w templates/workflow.af -V $variables -o $EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -L $2
fi
