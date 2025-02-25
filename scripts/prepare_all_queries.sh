#PREPARING OMIM QUERY
grep -P "Number Sign|Percent" $OMIM_QUERY_INPUT_DATA | grep -v "#" | cut -f 2,3 | cut -d ";" -f 1 | sed -E "s/([0-6][0-9]{5})/OMIM:\1/g" > $QUERIES_PATH/omim_list

#PREPARING HPO QUERY
semtools -O HPO -C CNS/HP:0000118 > $QUERIES_PATH/hpo_list
semtools --list_term_attributes -O HPO -S "," | awk '{FS="\t";OFS="\t"}{print $1,$2,$3-1}' | cut -f 1,3 > $TMP_PATH/HPO_terms_depth

#PREPARING DO QUERY
semtools -O DO -C CNS/DOID:4 > $QUERIES_PATH/do_list

#PREPARING GO QUERIES  #TODO Know how Sito makes 'we took all the terms from the three categories that are associated to at least one human gene in the “Gene Ontology Annotation” database (GOA)'
semtools -O GO -C CNS/GO:0005575 > $QUERIES_PATH/go_cc_list
semtools -O GO -C CNS/GO:0003674 > $QUERIES_PATH/go_mf_list
semtools -O GO -C CNS/GO:0008150 > $QUERIES_PATH/go_bp_list

#PREPARING MONDO QUERIES #TODO Sito makes 'we took all terms not cross-referenced to an HPO term in order to avoid MONDO terms describing symptoms'
semtools -O MONDO -C CNS/MONDO:0000001 > $QUERIES_PATH/mondo_list



############### WARNING: IT SEEMS THAT EFO, CL, UBERON AND CHEMI TERMS ARE ALWAYS INSIDE EACH OF THE FOLLOWING ONTOLOGY OBO FILES #################



#PREPARING EFO QUERIES #TODO Sito makes 'we retrieve all the terms linked to a trait in the Catalog of Genome-Wide Association Studies'
semtools -O EFO -C CNS/EFO:0000001 > $QUERIES_PATH/efo_list

#PREPARING CL QUERIES
semtools -O CL -C CNS/CL:0000000 > $QUERIES_PATH/cl_list

#PREPARING UBERON QUERIES
semtools -O UBERON -C CNS/UBERON:0000000 > $QUERIES_PATH/uberon_list