#! /usr/bin/env python
import argparse
import os
from collections import defaultdict

#################################################################################
## METHODS
#################################################################################

	

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-p", "--patients_profile", dest="patients_profile", default= None,
                    help="Path to file containing the patients profile (1 column data with 1 row for each phenotype)")

parser.add_argument("-s", "--pubmed_sims", dest="pubmed_sims", default= None,
                    help="Path to the file containing the pubmedID profiles (obtained from the semantic similarity analysis)")

parser.add_argument("-o", "--output_file", dest="output_file", default= None, 
                    help="Output file, with the table prepared for heatmap plotting")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################
