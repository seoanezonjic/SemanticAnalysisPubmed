#! /usr/bin/env python
from collections import Counter, defaultdict
import argparse, os


#################################################################################
## METHODS
#################################################################################

def read_and_load_omim_pmids(file_path, omim_dict):
	with open(file_path) as f:
		for line in f:
			omimID, PMIDs = line.strip().split("\t")
			PMIDS_list = PMIDs.split(",")
			omim_dict[omimID].extend(PMIDS_list)

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("--omim1_file", dest="omim1_file", default= None,
                    help="Path one of the omim benchmarks")

parser.add_argument("--omim2_file", dest="omim2_file", default= None,
                    help="Path to the other omim benchmark")

parser.add_argument("-o", "--output_file", dest="output_file", default= None,
                    help="Path to the output file")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

omim_dict = defaultdict(list)

read_and_load_omim_pmids(options["omim1_file"], omim_dict)
read_and_load_omim_pmids(options["omim2_file"], omim_dict)

with open(options["output_file"], "w") as f:
	for omimID, pmID in omim_dict.items():
		pmIDs_joined = ",".join(pmID)
		f.write(f"{omimID}\t{pmIDs_joined}\n")
