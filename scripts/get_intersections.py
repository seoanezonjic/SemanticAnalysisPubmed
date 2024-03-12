#! /usr/bin/env python

import sys
import gzip

def load_pmid_index(file):
	index = []
	with open(file) as f:
		for line in f:
			fields = line.rstrip().split("\t") # some keywords could have the second column (keyword matches) empty
			if len(fields) == 2:
				id, pmids_string = line.rstrip().split("\t")
				pmids = pmids_string.split(',')
				pmids = [int(pmid) for pmid in pmids]
				index.append([id, set(pmids)])
	return index

def get_intersections(pmid_indexA, pmid_indexB):
	intersections = {}
	for idA, Apmids in pmid_indexA:
		for idB, Bpmids in pmid_indexB:
			if idA == idB: continue
			pair = tuple(sorted([idA, idB]))
			if intersections.get(pair) == None:
				intersection = list(Apmids & Bpmids)
				if len(intersection) > 0:
					intersection.sort()
					intersections[pair] = intersection
	return intersections


pmid_index = load_pmid_index(sys.argv[1])

intersections = get_intersections(pmid_index, pmid_index)

f = gzip.open(sys.argv[2] + '.gz', 'wt') # Maybe save pickle in stream? gzip file?
for pair, intersection in intersections.items():
	f.write(f"{pair[0]}\t{pair[1]}\t{','.join([ str(i) for i in intersection ])}\n")
f.close()