#! /usr/bin/env python
from collections import Counter
import argparse, os
import copy, re
import numpy as np
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
            sims.append(round(float(sim), 4))
    return pmIDs, sims

def read_mondo_gold_standard(file_path):
    mondo = "None"
    mondo_related_pmids = []
    with open(file_path, 'r') as f:
        for line in f:
            mondo, pmIDs = line.strip().split('\t')
            mondo_related_pmids += [pmID.replace("PMID:", "") for pmID in pmIDs.split(",")]
    return mondo, mondo_related_pmids

def read_article_years_dict(file_path):
    article_years_dict = {}
    with open(file_path, 'r') as f:
        for idx, line in enumerate(f):
            if idx == 0: continue
            pmID, _original_file, publication_year, *_rest = line.strip().split('\t')
            article_years_dict[pmID] = int(publication_year.replace(".","").replace("c", ""))
    return article_years_dict
	

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-s", "--similitudes_file", dest="similitudes_file", default= None,
                    help="Path to file containing the pubmed profiles from stEngine results")

parser.add_argument("-m", "--mondo_goldstandard_profile", dest="mondo_goldstandard_profile", default= None,
                    help="Path to the file containing the MONDO Gold Standard profiles (MONDO:01, PMID:01,PMID:02,etc) one term at a time")

parser.add_argument("-p", "--pubmed_metada", dest="pubmed_metada", default= None,
                    help="Path to the file containing the pubmed metadata (PMID, original_file and publication_year)")

parser.add_argument("-o", "--output_file", dest="output_file", default= None, 
                    help="Output file with the filtered rankings for MONDO-associated PMIDs")

parser.add_argument("-t", "--top_ranking", dest="top_ranking", default= 0, type=int, 
                    help="Use it to output the first top K elements in the output file top_rankings")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

pmIDs, sims = read_similitudes_file(options['similitudes_file'])
mondo, mondo_related_pmids = read_mondo_gold_standard(options['mondo_goldstandard_profile'])
article_years_dict = read_article_years_dict(options['pubmed_metada'])
ranker_like_table = get_rank_metrics(sims, pmIDs, "best") #30972193   0.11771798479730065     0.02788639124141029     1676    192
#table_articles_years = [article_years_dict[record[0]] for record in ranker_like_table]
table_articles_years = [article_years_dict[record[0]] for record in ranker_like_table if article_years_dict.get(record[0])] #TODO: fix it and changed to previous version

repeated_positions = Counter([row[-1] for row in ranker_like_table])
with open(options['output_file'], 'w') as f:
    year_index = 0
    repeated_score = 0
    old_pos = ranker_like_table[0][3]
    for idx,row in enumerate(ranker_like_table):
        current_position = row[3]
        if current_position != old_pos:
            year_index = idx
            old_pos = current_position
        if row[0] in mondo_related_pmids:
            current_filtered_pmID = copy.deepcopy(row[0])
            row[0] = "PMID:" + current_filtered_pmID
            tab_joined_fields = '\t'.join([str(item) for item in row])
            n_newer_articles = np.sum(np.array(table_articles_years[:year_index]) > article_years_dict[current_filtered_pmID])
            n_older_articles = np.sum(np.array(table_articles_years[:year_index]) < article_years_dict[current_filtered_pmID])
            f.write(f"{tab_joined_fields}\t{mondo}\t{n_newer_articles}\t{n_older_articles}\t{repeated_positions[row[-1]]}\n")

if options["top_ranking"] > 0:
    with open("top_rankings", "a") as f:
        for idx,row in enumerate(ranker_like_table):
            if idx < options["top_ranking"]:
                tab_joined_fields = '\t'.join([str(item) for item in row])
                f.write(f"{tab_joined_fields}\t{mondo}\n")