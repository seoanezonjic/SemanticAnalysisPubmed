#!/usr/bin/env bash
source $PYENV/bin/activate

for ID in $database_ids
do
	grep $ID $TMP_PATH/phenotype.hpoa | grep -v description | cut -f 1,4 | sort -u > $TMP_PATH/$ID'_filtered_HP'
    #### TRANSLATED ####
	pattern=$ID
	if [ "$ID" == "ORPHA" ];then
		pattern="Orphanet"
	    awk '{print $2 "\t" $1 }' $TMP_PATH/$ID'_filtered_HP' | sed 's/ORPHA/Orphanet/g' | semtools -i - -O MONDO -k $pattern'[PS]*:[0-9]*' -o $TMP_PATH/$ID'2MONDO' --2cols
	else
	    awk '{print $2 "\t" $1 }' $TMP_PATH/$ID'_filtered_HP' | semtools -i - -O MONDO -k $pattern'[PS]*:[0-9]*' -o $TMP_PATH/$ID'2MONDO' --2cols
	fi
	awk '{print $2 "\t" $1 }' $TMP_PATH/$ID'2MONDO' > $TMP_PATH/$ID'2MONDO_raw'
done

#### MERGED TRANSLATED ####
cat $TMP_PATH/OMIM2MONDO_raw $TMP_PATH/ORPHA2MONDO_raw > $TMP_PATH/MERGED2MONDO_raw
sort -u $TMP_PATH/MERGED2MONDO_raw > $TMP_PATH/MERGED2MONDO_filtered_HP
#semtools -i $TMP_PATH/MERGED2MONDO_filtered_HP -O HPO -o $TMP_PATH/MERGED2MONDO -T "HP:0000118" --2cols --out2cols -c # Clean redundant HPO and childs not in phenotopyc abnormality
semtools -i $TMP_PATH/MERGED2MONDO_filtered_HP -O HPO -o $TMP_PATH/MERGED2MONDO -c -T "HP:0000118" --2cols --out2cols # Clean childs not in phenotopyc abnormality
aggregate_column_data -i $TMP_PATH/MERGED2MONDO -x 1 -a 2 > $INPUTS_PATH/mondo_hpo_profiles.txt