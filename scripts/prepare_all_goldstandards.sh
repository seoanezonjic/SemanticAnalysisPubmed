#! /usr/bin/env bash
#GS1	######### PREPARING MONDO-PMIDs AND MONDO-HPOs profiles ########
    #Download MONDO-PUMBED relations and MONDO-HP relations
    wget https://data.monarchinitiative.org/latest/tsv/all_associations/publication_disease.all.tsv.gz -O $TMP_PATH/publication_disease.all.tsv.gz
    wget http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa -O $TMP_PATH/phenotype.hpoa

    #Process MONDO-PUMBED relations
    zcat tmp/publication_disease.all.tsv.gz | tail -n +2 | cut -f 1,5,13 | grep MONDO | grep PMID | grep direct | cut -f 1,2 | sed "s/PMID://g" | \
            aggregate_column_data -i - -x 2 -a 1 > $INPUTS_PATH/mondo_pubmed_profiles.txt
    
    #Process MONDO-HP and OMIM-HP relations
    prepare_mondo_hp_relations.sh #Outpus to $INPUTS_PATH/mondo_hpo_profiles.txt and $INPUTS_PATH/omim_hpo_profiles.txt
    
    #Getting unique Disease IDs and PMIDs
    cut -f 1 $INPUTS_PATH/mondo_pubmed_profiles.txt | sort -u > $TMP_PATH/mondo_unique_diseaseIDs_raw
    cat $INPUTS_PATH/mondo_hpo_profiles.txt | grep -wf $TMP_PATH/mondo_unique_diseaseIDs_raw | cut -f 1 > $TMP_PATH/mondo_unique_diseaseIDs
    cat $INPUTS_PATH/mondo_pubmed_profiles.txt | grep -wf $TMP_PATH/mondo_unique_diseaseIDs | cut -f 2 | tr "," "\n" | sort -u > $TMP_PATH/mondo_unique_PMIDs


#GS2	######## PREPARING OMIM-PMIDs AND OMIM-HPOs profiles FROM DOID #######
    semtools -O DO --return_all_terms_with_user_defined_attributes 'id,def,xref' |  grep "OMIM" | grep "pubmed" > $TMP_PATH/DOID_raw_data
    get_required_fields_from_DO_goldstandard.py -i $TMP_PATH/DOID_raw_data -o $INPUTS_PATH/omim_pubmed_profiles.txt
    #alredady produced $INPUTS_PATH/omim_hpo_profiles.txt with prepare_mondo_hp_relations.sh script

    #Getting unique Disease IDs and PMIDs
    cut -f 1 $INPUTS_PATH/omim_pubmed_profiles.txt | sort -u > $TMP_PATH/omim_unique_diseaseIDs_raw
    cat $INPUTS_PATH/omim_hpo_profiles.txt | grep -wf $TMP_PATH/omim_unique_diseaseIDs_raw | cut -f 1 > $TMP_PATH/omim_unique_diseaseIDs
    cat $INPUTS_PATH/omim_pubmed_profiles.txt | grep -wf $TMP_PATH/omim_unique_diseaseIDs | cut -f 2 | tr "," "\n" | sort -u > $TMP_PATH/omim_unique_PMIDs


#GS3	######## PREPARING OMIM-PMIDs AND OMIM-HPOs profiles from Friederike Ehrhart paper ####### https://pubmed.ncbi.nlm.nih.gov/33947870/
    wget https://figshare.com/ndownloader/files/25769330 -O $TMP_PATH/omim2.txt
    tail -n +2 $TMP_PATH/omim2.txt | cut -f 3,4 | grep -E "[0-9]+\s[0-9]+" | awk 'BEGIN{FS="\t";OFS="\t"}{print "OMIM:"$2,$1}' |\
            aggregate_column_data -i - -x 1 -a 2 > $INPUTS_PATH/omim2_pubmed_profiles.txt		
    ln -s $INPUTS_PATH/omim_hpo_profiles.txt $INPUTS_PATH/omim2_hpo_profiles.txt



#### Downloads PMC-PMID equivalences for some full papers that does not have PMID field
wget https://ftp.ncbi.nlm.nih.gov/pub/pmc/PMC-ids.csv.gz -O $TMP_PATH/PMC-ids.csv.gz
zcat $TMP_PATH/PMC-ids.csv.gz | cut -d "," -f 9,10 | tail -n +2 | tr "," "\t" | awk '{ if(NF == 2) print $0}' > $INPUTS_PATH/PMC-PMID_equivalencies

#Getting unique Disease IDs and PMIDs
cut -f 1 $INPUTS_PATH/omim2_pubmed_profiles.txt | sort -u > $TMP_PATH/omim2_unique_diseaseIDs_raw
cat $INPUTS_PATH/omim2_hpo_profiles.txt | grep -wf $TMP_PATH/omim2_unique_diseaseIDs_raw | cut -f 1 > $TMP_PATH/omim2_unique_diseaseIDs
cat $INPUTS_PATH/omim2_pubmed_profiles.txt | grep -wf $TMP_PATH/omim2_unique_diseaseIDs | cut -f 2 | tr "," "\n" | sort -u > $TMP_PATH/omim2_unique_PMIDs