#! /usr/bin/env python
import argparse, os
from py_exp_calc.exp_calc import get_rank_metrics

#################################################################################
## METHODS
#################################################################################

def read_similitudes_file(file_path):
    pmIDs = []
    sims = []
    with open(file_path, 'r') as f:
        for line in f:
            pmID, _mondoID, sim = line.strip().split('\t')
            pmIDs.append(pmID)
            sims.append(float(sim))
    return pmIDs, sims

def read_mondo_gold_standard(file_path):
    mondo = "None"
    mondo_related_pmids = []
    with open(file_path, 'r') as f:
        for line in f:
            mondo, pmIDs = line.strip().split('\t')
            mondo_related_pmids += [pmID.replace("PMID:", "") for pmID in pmIDs.split(",")]
    return mondo, mondo_related_pmids
	

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-s", "--similitudes_file", dest="similitudes_file", default= None,
                    help="Path to file containing the pubmed profiles from stEngine results")

parser.add_argument("-m", "--mondo_goldstandard_profile", dest="mondo_goldstandard_profile", default= None,
                    help="Path to the file containing the MONDO Gold Standard profiles (MONDO:01, PMID:01,PMID:02,etc) one term at a time")

parser.add_argument("-o", "--output_file", dest="output_file", default= None, 
                    help="Output file")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

pmIDs, sims = read_similitudes_file(options['similitudes_file'])
mondo, mondo_related_pmids = read_mondo_gold_standard(options['mondo_goldstandard_profile'])
ranker_like_table = get_rank_metrics(sims, pmIDs)

with open(options['output_file'], 'a') as f:
    for row in ranker_like_table:
        if row[0] in mondo_related_pmids:
            row[0] = "PMID:" + row[0]
            tab_joined_fields = '\t'.join([str(item) for item in row])
            f.write(f"{tab_joined_fields}\t{mondo}\n")