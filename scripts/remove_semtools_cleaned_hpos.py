#! /usr/bin/env python
import argparse
import os
from collections import defaultdict
import warnings

#################################################################################
## METHODS
#################################################################################

def load_raw_profiles_with_sims(filepath):
    profiles_full_info = defaultdict(lambda: defaultdict(lambda: {}))
    with open(filepath) as f:
        for line in f:
            pmid, hpos, scores, tags = line.strip().split("\t")
            hpos = hpos.split(",")
            scores = scores.split(",")
            locations = tags.split(",")
            hpo_joined_info = zip(hpos, scores, locations)
            for hpo, score, location in hpo_joined_info: 
                profiles_full_info[pmid][hpo]["score"] = score
                profiles_full_info[pmid][hpo]["location"] = location
    return profiles_full_info

def load_cleaned_profiles(filepath):
    profiles = {}
    with open(filepath) as f:
        for line in f:
            pmid, hpos = line.strip().split("\t")
            profiles[pmid] = hpos.split(",")
    return profiles

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-i", "--input_file", dest="input_file", default= None,
                    help="Path to the tabulated file with PMID, HPOS, SIMS and LOCATIONS")

parser.add_argument("-f", "--filter_file", dest="filter_file", default= None,
                    help="Path to the cleaned PMID-HPO profiles")

parser.add_argument("-o", "--output_file", dest="output_file", default= None,
                    help="Path to the output file that has been already cleaned (Without parent-child HPO relationships)")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

raw_profiles_full_info = load_raw_profiles_with_sims(options["input_file"])
cleaned_profiles = load_cleaned_profiles(options["filter_file"])

with open(options['output_file'], 'w') as f:
    for pmid, hps in cleaned_profiles.items():
        current_pmid_hps = []
        current_pmid_scores = []
        current_pmid_locations = []
        for hp in hps:
            current_pmid_hps.append(hp)
            current_pmid_scores.append(raw_profiles_full_info[pmid][hp]["score"])
            current_pmid_locations.append(raw_profiles_full_info[pmid][hp]["location"])
        hps_joined = ','.join(current_pmid_hps)
        scores_joined = ','.join(current_pmid_scores) 
        locations_joined = ','.join(current_pmid_locations)               
        f.write(f"{pmid}\t{hps_joined}\t{scores_joined}\t{locations_joined}\n")
            