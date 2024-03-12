#! /usr/bin/env bash

export CURRENT_PATH=`pwd`
export EXEC_PATH=$CURRENT_PATH/results
export CODE_PATH=$CURRENT_PATH/scripts
export PUBMED_PATH=$FSCRATCH/software_data/pubmed
export MODEL_PATH=$CURRENT_PATH/models
export MODEL_NAME="all-mpnet-base-v2"
#export MODEL_NAME="all-MiniLM-L6-v2"
export CURRENT_MODEL=$MODEL_PATH/$MODEL_NAME

if [ "$1" == "1" ] ; then # DOWNLOAD MODEL
        mkdir -p $MODEL_PATH
        . ~soft_bio_267/initializes/init_python
        $CODE_PATH/downloading_model.py $MODEL_NAME $CURRENT_MODEL 
elif [ "$1" == "2" ] ; then
        source ~soft_bio_267/initializes/init_autoflow
        variables=`echo -e "
                \\$code_path=$CODE_PATH,
                \\$model_name=$MODEL_NAME,
        	\\$current_model=$CURRENT_MODEL,
                \\$min_similarity=0.5,
                \\$pubmed_path=$PUBMED_PATH        
            " | tr -d [:space:]`
        AutoFlow -e -w templates/workflow.af -V $variables -o $EXEC_PATH -m 20gb -t 3-00:00:00 -n cal -L $2
fi
