#! /usr/bin/env python
import argparse, os, glob, sys, json
import pandas as pd
from collections import defaultdict
from py_cmdtabs import CmdTabs
from py_exp_calc.exp_calc import flatten, dataframe2lists

#################################################################################
## METHODS
#################################################################################

def load_papers_file(filename):
    pmids_and_content = {}
    with open(filename) as f:
        for line in f:
            pmid, content = line.strip().split("\t")
            full_text = (" ".join(flatten(json.loads(content)))).lower().replace("‐", "-")
            pmids_and_content[pmid] = full_text
    return pmids_and_content

def check_raso_mention(raso, pmid, raso_aliases, pmids_and_content):
    for raso_alias in raso_aliases[raso]:
        if raso_alias in pmids_and_content[pmid]:
            return True
    return False

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-i", "--input_table", dest="input_table", default= None, 
                    help="Input table of top10 aggregated PMIDs")

parser.add_argument("-p", "--papers_fulltext", dest="papers_fulltext", default= None,
                    help="Two columns file with PMIDS and a JSON with the full body text of the paper")

parser.add_argument("-o", "--output_file", dest="output_file", default= None,
                    help="Output file with the aggregated table")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

#pmid	MeanRank	title	noonan_rank	nf_rank	costello_rank	cfc_rank
rasopathies = ["noonan", "nf-noonan", "nf", "costello", "cfc"]
raso_alias = {"noonan":["noonan"], 
              "nf-noonan": ["neurofibromatosis-noonan", "nf-noonan", "nfns syndrome", "noonan-neurofibromatosis",  "neurofibromatosis type 1-noonan",  "neurofibromatosis with noonan phenotype"],
              "nf": ["neurofibromatosis", "nf syndrome", "nf1 syndrome", "nf-1 syndrome"], 
              "cfc": ["cardiofaciocutaneous", "cardiofacio-cutaneous", "cardio-facio-cutaneous", "cfc syndrome"], 
              "costello": ["costello"]}

keywords = ["noonan", "cfc", "cardiofaciocutaneous", "cardiofacio-cutaneous", "cardio-facio-cutaneous", "costello", "nf1", "nf-1", "neurofibromatosis",
	    "rare disease", "rasopathy", "rasopathies", "leopard", "watson", "legius", "neurofibromatosis-noonan", "nf-noonan", "nfns", "noonan neurofibromatosis",  
        "noonan-neurofibromatosis",  "neurofibromatosis type 1-noonan",  "neurofibromatosis with noonan phenotype"]
 

pmids_and_content = load_papers_file(options['papers_fulltext'])
top10_table = CmdTabs.load_input_data(options['input_table'])
top10_table_df = pd.DataFrame(top10_table[1:], columns=top10_table[0])
top10_table_df.index = list(top10_table_df['pmid'])
top10_table_df.drop(columns=['pmid'], inplace=True)

apply_bold = lambda text: f'\\textbf{{{text}}}'
for pmid in top10_table_df.index:
    title = top10_table_df.loc[pmid, "title"]
    for kw in keywords: title = title.replace(kw, apply_bold(kw))
    top10_table_df.loc[pmid, "title"] = title

    for raso in rasopathies:
        raso_mentioned = check_raso_mention(raso, pmid, raso_alias, pmids_and_content)
        cell_content = top10_table_df.loc[pmid, f"{raso}_rank"]
        top10_table_df.loc[pmid, f"{raso}_rank"] = apply_bold(cell_content) if raso_mentioned else cell_content

final_table = dataframe2lists(top10_table_df, "pmid")

indexes = ["Index"] + [str(idx) for idx in range(1,len(final_table))]
with open(options["output_file"], "w") as f:
    for idx,row in enumerate(final_table):
        if idx > 0: row[1] = str(round(float(row[1]),3)) #Rounding similarity value to 3 decimals
        indexed_row = [indexes[idx]] + row
        joined_row = " & ".join(indexed_row)
        f.write(joined_row+"\\\\ \\hline\n")