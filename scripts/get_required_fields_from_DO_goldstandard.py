#! /usr/bin/env python
import argparse, os, re
from py_cmdtabs import CmdTabs

#################################################################################
## METHODS
#################################################################################

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-i", "--input_file", dest="input_file", default= None,
                    help="Path to file containing a TSV with DOID, def and xrefs")

parser.add_argument("-o", "--output_file", dest="output_file", default= None, 
                    help="Path to the file to save OMIM-PMIDs profile")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################


doi_pmid_omim_data = CmdTabs.load_input_data(options["input_file"])

output_table = []
for row in doi_pmid_omim_data:
    pmid_regex1 = re.findall(r"ncbi.nlm.nih.gov/pubmed/([0-9]+)", row[1])
    pmid_regex2 = re.findall(r"pubmed.ncbi.nlm.nih.gov/([0-9]+)", row[1])
    pmid_regex_results = pmid_regex1 + pmid_regex2
    if pmid_regex_results:
        pmids_csv = ",".join(pmid_regex_results) 
        regex_omim = re.findall(r"(OMIM:[0-9]+)", row[2])
        for omim in regex_omim:
            output_table.append(f"{omim}\t{pmids_csv}\n")

with open(options["output_file"], "w") as f:
    for row in output_table:
        f.write(row)