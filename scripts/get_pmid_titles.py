#! /usr/bin/env python
import argparse
import sys
import os
import glob
import re
import requests
import json
from json import JSONDecodeError
from py_cmdtabs import CmdTabs
from metapub import PubMedFetcher
fetch = PubMedFetcher()

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-i", "--input_data", dest="input_data", default= None,
                    help="Input data file")

parser.add_argument("-o", "--output_path", dest="output_path", default= None, 
                    help="Output data path")

opts = parser.parse_args()
options = vars(opts)

#################################################################################

pmids_titles = []
pmids = CmdTabs.load_input_data(options["input_data"])
pmids = list(set([pmid[0].replace("PMID:", "") for pmid in pmids]))

for i in range(0, len(pmids), 100):
    successful_fetch = False
    trials = 0
    while not successful_fetch and trials < 5:
        try:
            print(f"Processing {i} to {i+100}")
            pmids_chunk = pmids[i:i+100]
            pmids_joined = ",".join(pmids_chunk)
            url= f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id={pmids_joined}&retmode=json"
            #make a request to the API and convert the resulting json to a python dictonary
            response = requests.get(url)
            response_dict = json.loads(response.text)

            for pmid in pmids_chunk:
                title = response_dict['result'][pmid]['title']
                pmids_titles.append([pmid, title])
            successful_fetch = True
        except JSONDecodeError as e:
            print(f"Warning: problem trying to fetch data between this range : {e}")

CmdTabs.write_output_data(pmids_titles, output_path=options["output_path"])