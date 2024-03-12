#! /usr/bin/env python

import sys
import pickle

from sentence_transformers import SentenceTransformer, util

###################################################################################################
## METHODS
###################################################################################################
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


###################################################################################################
## MAIN
###################################################################################################
print("Load keywords")
keyword_index = load_keyword_index(sys.argv[2]) # keywords used in queries
print("Collect queries")
queries = []
query_ids = []
for kwdID, kwds in keyword_index.items():
	queries.extend(kwds)
	query_ids.extend([kwdID for i in range(0, len(kwds))])

print("Load model")
embedder = SentenceTransformer(sys.argv[1], cache_folder =sys.argv[3])
print("Encode queries")
query_embeddings = embedder.encode(queries, show_progress_bar = False, convert_to_numpy=True) #convert_to_tensor=True
print("Write query embedding")
with open(sys.argv[4] + '.pkl', "wb") as fOut:
	pickle.dump({'query_ids': query_ids, "queries": queries, "embeddings": query_embeddings}, fOut)

