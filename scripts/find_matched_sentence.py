#! /usr/bin/env python
import argparse, os, json

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("--query_hpo", dest="query_hpo", default= None,
                    help="")
parser.add_argument("--sentences", dest="sentences", default= None, type = lambda filename: open(filename).read().strip(),
                    help="")
parser.add_argument("--hpo_locs", dest="hpo_locs", default= None, type = lambda filename: open(filename).read().strip().split("\t"),
                    help="")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

sentences = json.loads(options['sentences'])
query_hpo = options["query_hpo"]

pmid, hpos, locations = options["hpo_locs"]
hpos = hpos.split(",")
locations = locations.split(",")

query_hpo_idx = hpos.index(query_hpo)
query_hpo_locations = locations[query_hpo_idx]
query_hpo_locations = query_hpo_locations.split(";")

for query_hpo_location in query_hpo_locations:
    paragraph, sentence = [ int(indxx) for indxx in query_hpo_location.split("_")]
    print(sentences[paragraph][sentence])