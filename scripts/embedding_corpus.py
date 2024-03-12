#! /usr/bin/env python

import sys
import gzip
import pickle
from termcolor import cprint

from sentence_transformers import SentenceTransformer, util

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


###################################################################################################
## MAIN
###################################################################################################
embedder = SentenceTransformer(sys.argv[1], cache_folder =sys.argv[2])
pubmed_index = load_pubmed_index(sys.argv[3]) # abstracts
textIDs = list(pubmed_index.keys())
corpus = list(pubmed_index.values())
corpus_embeddings = embedder.encode(corpus, convert_to_numpy=True) #convert_to_tensor=True
with open(sys.argv[4] + '.pkl', "wb") as fOut:
	pickle.dump({'textIDs': textIDs, "corpus": corpus, "embeddings": corpus_embeddings}, fOut)

