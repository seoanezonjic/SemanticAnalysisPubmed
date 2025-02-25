#! /usr/bin/env python
import argparse
import os, sys
from collections import defaultdict
import warnings

#################################################################################
## METHODS
#################################################################################


def load_ranks(filepath):
    ranks = []
    with open(filepath) as f:
        for line in f:
            pmid, rank, sim, title = line.strip().split("\t")
            sim = round(float(sim),2)
            ranks.append([pmid, sim, title])
    return ranks


#################################################################################
## MAIN
#################################################################################

keywords = ["rare diseases", "noonan", "cardiofaciocutaneous", "cfc", "nf", "neurofibromatosis"]
check_keywords = lambda title: not any([keyw in title.lower() for keyw in keywords])

filename = sys.argv[1]
ranks = load_ranks(filename)

sorted_ranks = sorted(ranks, key=lambda x: (1-x[1], check_keywords(x[2]), x[2]), reverse=False)
for idx, (pmid, sim, title) in enumerate(sorted_ranks):
    print(f"{pmid}\t{idx+1}\t{sim}\t{title}")