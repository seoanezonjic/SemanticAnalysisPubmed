#! /usr/bin/env python
import argparse, inspect
from py_cmdtabs import CmdTabs


##### FUNCTIONS #####
def load_latex_table(filename):
        table = []
        with open(filename) as f:
                for line in  f:
                        rank, pmid, sim, title = line.strip().replace("\\\\ \\hline", "").split(" & ")
                        table.append([rank, pmid, sim, title])
        return table

def conditional_shorten_title(title, max_length):
        if "textbf" not in title and len(title) > max_length:
                split_title = title.split(" ")
                for idx in range(1, len(split_title)):
                        total_length = len(" ".join(split_title[:idx]))
                        if total_length > max_length:
                                title = " ".join(split_title[:idx])+"(...)"
                                break
        return title

##### OPT PARSE #####
parser = argparse.ArgumentParser(description=f'Usage: {inspect.stack()[0][3]} [options]')
parser.add_argument("-i", "--input_file", dest="input_file", default= None,
                    help="Latex input file")
parser.add_argument("-o", "--output_file", dest="output_file", default=None,
                    help="Latex output file")
parser.add_argument("--max_length", dest="max_length", default= 90, type= int,
                    help="Maximum title length")
opts = parser.parse_args()
options = vars(opts)

##### MAIN #####
input_table = load_latex_table(options['input_file'])
shortened_titles_table = []

for top, candidate, value, candidate_title in input_table:
        shortened_title = conditional_shorten_title(candidate_title, options['max_length'])
        shortened_titles_table.append([top, candidate, value, shortened_title])

with open(options['output_file'], "w") as f:
        for row in shortened_titles_table: 
                f.write(" & ".join(row)+"\\\\ \\hline\n")