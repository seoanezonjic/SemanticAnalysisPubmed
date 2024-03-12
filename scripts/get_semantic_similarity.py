#! /usr/bin/env python

import sys
import pickle
import gzip
from termcolor import cprint

from sentence_transformers import util
import torch

###################################################################################################
## METHODS
###################################################################################################
def load_pubmed_index(file):
	pubmed_index = {}
	with open(file) as f:
		for line in f:
			id, text = line.rstrip().split("\t")
			pubmed_index[int(id)] = text
	return pubmed_index

def load_text_id_per_kwrd(file):
	tid_kwrd = {}
	with open(file) as f:
		for line in f:
			fields = line.rstrip().split("\t")
			if len(fields) == 2: # Some keywords could have not results. Skip
				kwd_id, textIds = fields
				textIds = [ int(tid) for tid in textIds.split(',') ]
				tid_kwrd[kwd_id] = textIds
	return tid_kwrd




###################################################################################################
## MAIN
###################################################################################################
print("Load pre-computed CORPUS embeddings from disc")
with open(sys.argv[1], "rb") as fIn:
	cache_data = pickle.load(fIn)
	corpus_ids = cache_data["textIDs"]
	corpus_sentences = cache_data["corpus"]
	corpus_embeddings = cache_data["embeddings"]

print("Load pre-computed QUERY embeddings from disc")
with open(sys.argv[2], "rb") as fIn:
	cache_data = pickle.load(fIn)
	query_ids = cache_data['query_ids']
	queries = cache_data["queries"]
	query_embeddings = cache_data["embeddings"]


print("Semantic search")
search = util.semantic_search(query_embeddings, corpus_embeddings, top_k=int(sys.argv[4]))

print("Get best match per keyword")
best_matches = {}
for i,query in enumerate(search):
	kwdID = query_ids[i]
	kwd = best_matches.get(kwdID)
	if kwd == None:
		kwd = {}
		best_matches[kwdID] = kwd

	for hit in query:
		textID = corpus_ids[hit['corpus_id']]
		score = hit['score']
		text_score = kwd.get(textID)
		if text_score == None or text_score < score :
			kwd[textID] = score
		#sentence = corpus_sentences[hit['corpus_id']]

with open(sys.argv[3], 'w') as f:
	for kwdID, matches in best_matches.items():
		for textID, score in matches.items():
			f.write(f"{kwdID}\t{textID}\t{score}\n")