#! /usr/bin/env python

import sys
import gzip
from termcolor import cprint

from sentence_transformers import SentenceTransformer, util
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

def load_coocurrences(file):
	coocurrences = []
	with gzip.open(file, 'rt') as f:
		for line in f:
			id1, id2, pmids_string = line.rstrip().split("\t")
			pmids = [ int(pmid) for pmid in pmids_string.split(',')]
			coocurrences.append([id1, id2, pmids])
	return coocurrences

def load_keyword_index(file):
    keywords = {}
    with open(file) as f:
        for line in f:
            fields = line.rstrip().split("\t")
            if len(fields) == 2:
                id, keyword = fields
                keywords[id] = [keyword.lower()]
            else:
                id, keyword, alternatives = fields
                alternatives = alternatives.split(',')
                alternatives.append(keyword)
                alternatives = [ a.lower() for a in alternatives ]
                kwrds = list(set(alternatives))
                keywords[id] = kwrds
    return keywords


def get_texts(pubmed_index, pmids):
	texts = []
	count = 1
	for pmid in pmids:
		text = pubmed_index.get(pmid)
		if text != None: 
			texts.append(text)
			count += 1
		if count == 10: break
	return texts

###################################################################################################
## MAIN
###################################################################################################
print("Load pubmed")
pubmed_index = load_pubmed_index(sys.argv[1]) # abstracts
print("Load intersections")
coocurrences = load_coocurrences(sys.argv[2]) # intersections
print("Load keywords")
keyword_index = load_keyword_index(sys.argv[3]) # keywords used in queries

print("Load model")
embedder = SentenceTransformer("all-MiniLM-L6-v2")

print("Check intersections in model")
for id1, id2, pmids in coocurrences:
	texts = get_texts(pubmed_index, pmids)
	cprint('=========================================================================', 'yellow')
	cprint('=========================================================================', 'yellow')
	cprint(f"{id1} <=> {id2}", 'yellow')
	if len(texts)> 0:
		corpus_embeddings = embedder.encode(texts, convert_to_tensor=True)
		kwds1 = keyword_index[id1]
		kwds2 = keyword_index[id2]
		cprint('###################################################################', 'blue')
		cprint(kwds1, 'green')
		cprint(kwds2, 'red')
		queries = kwds1 + kwds2

		query_embeddings = embedder.encode(queries, convert_to_tensor=True)

		q_hits = util.semantic_search(query_embeddings, corpus_embeddings, top_k=5)
		for i,q_hit in enumerate(q_hits):
			print("\n\n======================\n\n")
			print("Query:", queries[i])
			print("\nTop 5 most similar sentences in corpus:")
			for hit in q_hit:
				print(texts[hit['corpus_id']], "(Score: {:.4f})".format(hit['score']))
