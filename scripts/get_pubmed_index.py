#! /usr/bin/env python

import sys
import gzip
import xml.etree.ElementTree as ET


def get_abstract_index(file): 
	texts = [] # aggregate all abstracts in XML file
	with gzip.open(file) as gz:
		mytree = ET.parse(gz)
		pubmed_article_set = mytree.getroot()
		for article in pubmed_article_set:
			pmid = None
			for data in article.find('MedlineCitation'):
				if data.tag == 'PMID':
					pmid = data.text
				abstract = data.find('Abstract')
				if abstract != None:
					for i in abstract:
						abstractText = abstract.find('AbstractText')
						if abstractText != None:
							txt = abstractText.text
							texts.append([pmid, txt])
	return texts


abstract_index = get_abstract_index(sys.argv[1])

with open(sys.argv[2], 'w') as f:
	for pmid, text in abstract_index:
		f.write(f"{pmid}\t{text}\n")