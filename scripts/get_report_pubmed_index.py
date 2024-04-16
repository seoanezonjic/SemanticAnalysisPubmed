#! /usr/bin/env python

from py_report_html import Py_report_html
import sys, os, argparse
from collections import defaultdict

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-d", "--data_file", dest="data_file", default= None,
                    help="Path to file containing the abstract related stats returned from xml abstracts parsing")

parser.add_argument("-t", "--template_file", dest="template_file", default= None,
                    help="Path to the template file to be used for the report generation")

parser.add_argument("-o", "--output_file", dest="output_file", default= None, 
                    help="Path to the output file to be generated with the report")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

#Warning line example where stats are extracted:
#file=/mnt2/fscratch/users/pab_001_uma/pedro/software_data/pubmed/pubmed24n0881.xml.gz,total=30000,no_abstract=4562,no_pmid=0
file_raw_stats = []
file_proportion_stats = []

all_total = 0
all_abstract = 0
all_no_abstract = 0
all_no_pmid = 0

counter = -1
with open(options["data_file"]) as f:
    for line in f:
        stats = line.strip().split('stats:')[1]
        stats = stats.split(',')
        file_stats = {key:int(value) if value.isnumeric() else value for key, value in map(lambda x: x.split("="), stats)}

        counter += 1
        file_raw_stats.append([f"row {counter}",
                               file_stats["file"], 
                               file_stats["total"], 
                               file_stats["no_abstract"], 
                               file_stats["no_pmid"], 
                               file_stats["total"]-file_stats["no_abstract"]-file_stats["no_pmid"]  ])
        
        file_proportion_stats.append([f"row {counter}",
                                      file_stats["file"], 
                                      file_stats["no_abstract"]/file_stats["total"], 
                                      file_stats["no_pmid"]/file_stats["total"],
                                      1 - (file_stats["no_abstract"]+file_stats["no_pmid"])/file_stats["total"]  ])

        all_total += file_stats["total"]
        all_no_abstract += file_stats["no_abstract"]
        all_no_pmid += file_stats["no_pmid"]
        all_abstract += file_stats["total"]-file_stats["no_abstract"]-file_stats["no_pmid"]

file_raw_stats = sorted(file_raw_stats, key=lambda x: x[3], reverse=True)
file_proportion_stats = sorted(file_proportion_stats, key=lambda x: x[2], reverse=True)

file_raw_stats = [["rows", "Filename", "total", "no_abstract","no_pmid", "abstract"]] + file_raw_stats
file_proportion_stats = [["rows", "Filename", "proportion_no_abstract", "proportion_no_pmid", "proportion_abstract"]] + file_proportion_stats

all_no_abstract_proportion = all_no_abstract/all_total
all_no_pmid_proportion = all_no_pmid/all_total
all_abstract_proportion = all_abstract/all_total

total_stats = [["rows", "all_total", "no_abstract", "no_pmid", "abstract"], ["row 0", all_total, all_no_abstract, all_no_pmid, all_abstract]]
total_proportion_stats = [["rows", "proportion_no_abstract", "proportion_no_pmid", "proportion_abstract"], ["row 0", all_no_abstract_proportion, all_no_pmid_proportion, all_abstract_proportion]]

container = {'file_raw_stats' : file_raw_stats, 'file_proportion_stats' : file_proportion_stats, 'total_stats' : total_stats, 'total_proportion_stats' : total_proportion_stats}
template = open(options["template_file"]).read()
report = Py_report_html(container, options["output_file"], True, True)
report.build(template)
report.write(f'{options["output_file"]}.html')