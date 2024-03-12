#! /usr/bin/env python

import sys
from termcolor import cprint
import spacy 
from flashtext import KeywordProcessor

def load_pubmed_index(file):
	pubmed_index = {}
	with open(file) as f:
		for line in f:
			id, text = line.rstrip().split("\t")
			pubmed_index[int(id)] = text
	return pubmed_index

def load_coocurrences(file):
	coocurrences = []
	with open(file) as f:
		for line in f:
			id1, id2, pmids_string = line.rstrip().split("\t")
			pmids = [ int(pmid) for pmid in pmids_string.split(',')]
			coocurrences.append([id1, id2, pmids])
	return coocurrences

def load_keyword_index(file):
	keyword_index = {}
	with open(file) as f:
		for line in f:
			id, keywords, pmids = line.rstrip().split("\t")
			keyword_index[id] = keywords.split(',')
	return keyword_index

def get_texts(pubmed_index, pmids):
	texts = []
	for pmid in pmids:
		text = pubmed_index.get(pmid)
		if text != None: texts.append(text)
	return texts

def get_keywords(keywords):
	keyword_processor = KeywordProcessor()
	for k in keywords:
		keyword_processor.add_keyword(k)
	return keyword_processor

def lemmatize_words(nlp, kwds):
	lm_kwds = []
	for kw in kwds:
		doc = nlp(kw)
		for token in doc: lm_kwds.append(token.lemma_)
	return lm_kwds



pubmed_index = load_pubmed_index(sys.argv[1]) # abstracts
coocurrences = load_coocurrences(sys.argv[2]) # intersections
keyword_index = load_keyword_index(sys.argv[3])

nlp = spacy.load('en_core_web_sm')

for id1, id2, pmids in coocurrences:
	texts = get_texts(pubmed_index, pmids)
	if len(texts)> 0:
		kwds1 = keyword_index[id1]
		kwds2 = keyword_index[id2]
		print(kwds1)
		print(kwds2)
		lm_keys1 = lemmatize_words(nlp, kwds1)
		lm_keys2 = lemmatize_words(nlp, kwds2)
		keyword_processor1 = get_keywords(lm_keys1)
		keyword_processor2 = get_keywords(lm_keys2)
		for text in texts:
			print(text)
			print('--------------')
			cprint(lm_keys1, 'green')
			cprint(lm_keys2, 'green')
			print(keyword_processor1.extract_keywords(text))
			print(keyword_processor2.extract_keywords(text))
		print('############################')
