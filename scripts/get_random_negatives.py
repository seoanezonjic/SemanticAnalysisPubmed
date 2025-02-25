#! /usr/bin/env python
import argparse, os, numpy

#################################################################################
## METHODS
#################################################################################

def read_one_column_file(filename):
    return [ item.strip() for item in open(filename).readlines() ]

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("--all_pmids", dest="all_pmids", default= None,
                    help="Path to file containing the pubmed profiles from stEngine results")

parser.add_argument("--pmids_to_skip", dest="pmids_to_skip", default= None,
                    help="Path to file containing the pubmed profiles from stEngine results")

parser.add_argument("--randoms_number", dest="randoms_number", type = int,
                    help="Path to file containing the pubmed profiles from stEngine results")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

all_pmids = set(read_one_column_file(options['all_pmids']))
pmids_to_skip = set(read_one_column_file(options['pmids_to_skip']))
random_number = options['randoms_number']

pmids_to_choose = list( all_pmids.difference(pmids_to_skip) )
chosen_pmids = numpy.random.choice(pmids_to_choose, random_number, replace=False)
for pmid in chosen_pmids: print(pmid)