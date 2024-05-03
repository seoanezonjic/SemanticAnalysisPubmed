#! /usr/bin/env python
import argparse
import os
from collections import defaultdict

#################################################################################
## METHODS
#################################################################################

def load_similarities(filename):
    pmids = {}
    with open(filename) as f:
        for line in f:
            pmid_and_tag, hp, score = line.strip().split('\t')
            pmid, tag = pmid_and_tag.split('_', maxsplit=1)
            if pmid not in pmids:
                pmids[pmid] = {}
            if hp not in pmids[pmid]:
                pmids[pmid][hp] = {}
                pmids[pmid][hp]["location"] = [tag]
                pmids[pmid][hp]["score"] = [score]
            else:
                pmids[pmid][hp]["location"].append(tag)
                pmids[pmid][hp]["score"].append(score)
    return pmids

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-i", "--input_file", dest="input_file", default= None,
                    help="Path to the file with HP, PMID and similarity score (obtained from the semantic similarity analysis)")

parser.add_argument("-o", "--output_file", dest="output_file", default= None,
                    help="Path to the output file with the collapsed HPs")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

pmids = load_similarities(options['input_file'])
with open(options['output_file'], 'w') as f:
    for pmid in pmids:
        for hp in pmids[pmid]:
            tags = pmids[pmid][hp]["location"]
            scores = pmids[pmid][hp]["score"]
            f.write(f'{pmid}\t{hp}\t{";".join(scores)}\t{";".join(tags)}\n')