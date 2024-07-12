#! /usr/bin/env python
import argparse, os, copy
from collections import defaultdict
from py_exp_calc.exp_calc import get_rank_metrics

#################################################################################
## METHODS
#################################################################################

#OMIM:101600    PMID142534_1_32   0.7   
def load_topk_file(filename):
    similarities = defaultdict(list)
    disease = "None"
    with open(filename) as f:
        for line in f:
            disease, pmid_paragraph_sentence, score = line.strip().split("\t")
            pmid = pmid_paragraph_sentence.split("_")[0]
            similarities[pmid].append(float(score))
    similarities = {pmid: max(scores) for pmid, scores in similarities.items()}
    return similarities, disease

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-i", "--input_file", dest="input_file", default= None,
                    help="")
parser.add_argument("-f", "--filter_file", dest="filter_file", default= None,
                    help="")
parser.add_argument("-o", "--output_file", dest="output_file", default= None,
                    help="")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

topk, disease = load_topk_file(options['input_file'])
sims, pmIDs = list(topk.values()), list(topk.keys())
max_sim = max(sims)
min_sim = min(sims)

pmids_to_filter = open(options['filter_file']).read().splitlines()
ranker_like_table = get_rank_metrics(sims, pmIDs)

with open(options['output_file'], 'w') as f:
    for idx,row in enumerate(ranker_like_table):
        current_filtered_pmID = copy.deepcopy(row[0])
        row[0] = "PMID:" + current_filtered_pmID
        row[1] = (row[1] - min_sim) / (max_sim - min_sim)
        tab_joined_fields = '\t'.join([str(item) for item in row])
        is_gold_standard = 1 if current_filtered_pmID in pmids_to_filter else 0
        f.write(f"{tab_joined_fields}\t{disease}\t{is_gold_standard}\n")