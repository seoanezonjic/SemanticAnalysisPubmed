#! /usr/bin/env python

import sys
from sentence_transformers import SentenceTransformer

SentenceTransformer(sys.argv[1], cache_folder =sys.argv[2])

