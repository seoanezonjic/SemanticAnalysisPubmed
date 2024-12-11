#!/usr/bin/env python3

all_sims = []
with open("prueba.txt") as f:
	for line in f:
		pmid, hpo, sims, loc = line.strip().split("\t")
		sims_s = sims.split(";")
		locs_s = loc.split(";")
		for idx in range(len(sims_s)): 
			all_sims.append([ hpo,pmid,float(sims_s[idx]),locs_s[idx] ])

all_sims.sort(key=lambda data: data[2], reverse=True)

for row in all_sims:
	if row[2] < 0.8:
		print(row)
		break
