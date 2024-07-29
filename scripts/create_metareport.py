#! /usr/bin/env python
import argparse
import sys
import os
import glob
import re

from py_report_html import Py_report_html
from py_semtools.ontology import Ontology

def parse_paths(string): return re.sub(r"\s+", '', string).split(',')
def parse_args(args=None):
	if args == None: args = sys.argv[1:]
	parser = argparse.ArgumentParser(description='Perform Network analysis from NetAnalyzer package')
	parser.add_argument("-t", "--template", dest="template", default= None, 
						help="Input template file")
	parser.add_argument("-a", "--aux_templates", dest="aux_templates", default= None,
						help="Path to additional templates that must be included. Use ',' as path separator for each file")
	parser.add_argument("-o", "--report", dest="output", default= 'Report', 
						help="Path to generated html file (without extension)")
	parser.add_argument("-d", "--data_files", dest="data_files", default= [], type=parse_paths,
						help="Text files with data to use on graphs or tables within report")
	parser.add_argument("-j", "--javascript_files", dest="javascript_files", default= [], type=parse_paths,
						help="Path to javascript files that must be included. Use ',' as path separator for each file")
	parser.add_argument("-c", "--css_files", dest="css_files", default= [], type=parse_paths,
						help="Path to css files that must be included. Use ',' as path separator for each file")
	parser.add_argument("-J", "--javascript_cdn", dest="javascript_cdn", default= [], type=parse_paths,
						help="URL to javascript CDNs that must be included. Use ',' as path separator for each file")
	parser.add_argument("-C", "--css_cdn", dest="css_cdn", default= [], type=parse_paths,
						help="URL to css CDNs that must be included. Use ',' as path separator for each file")
	parser.add_argument("-u", "--uncompressed_data", dest="uncompressed_data", default=True, action='store_false',
						help="Delete redundant items")
	parser.add_argument("-m", "--menu", dest="menu", default= 'contents_list', 
						help="Indicate if indexed content must be a contents list (contents_list) or a menu (menu)")	
	parser.add_argument("-O" , "--ontology", dest="ontology", default= None,
                        help="Path to HPO ontology file")
	parser.add_argument("-M" , "--mondo", dest="mondo", default= None,
                        help="Path to MONDO ontology file")	
	parser.add_argument("-R" , "--regex", dest="regex", default= None,
						help="Regex to select MONDO terms")
	opts =  parser.parse_args(args)
	main_py_report_html(opts)

def load_files(data_files):
	container = {}
	for file_path in data_files:
		if not os.path.exists(file_path): sys.exit(f"File path {file_path} not exists") 
		data_id = os.path.basename(file_path)
		data = parse_tabular_file(file_path)
		container[data_id] = data
	return container

def parse_tabular_file(file_path):
	with open(file_path) as f:
		data = [line.rstrip().split("\t") for line in f]
	return data

def main_py_report_html(options):
	if not os.path.exists(options.template): sys.exit('Template file not exists')
	template = open(options.template).read()

	if len(options.data_files) == 0: sys.exit('Data files has not been specified')
	container = load_files(options.data_files)

	#loading HPO ontology
	ontology = Ontology(file=options.ontology, load_file = True)
	container['ontology'] = ontology

	#loading MONDO ontology
	mondo = Ontology(file = options.mondo, load_file = True, extra_dicts = [['xref', {'select_regex': eval('r"'+options.regex+'"'), 'store_tag': 'tag', 'multiterm': True}]])
	mondo.precompute()
	omim_to_mondo_raw_dict = mondo.dicts["tag"]["byValue"]
	omim_to_mondo_dict = {omim.replace("PS",""):list(set(mondos)) for omim, mondos in omim_to_mondo_raw_dict.items()}
	container["omim_to_mondo_dict"] = omim_to_mondo_dict

	Py_report_html.additional_templates.append(options.aux_templates)
	report = Py_report_html(container, os.path.basename(options.output), True, options.uncompressed_data, options.menu)
	report.add_js_files(options.javascript_files)
	report.add_css_files(options.css_files)
	report.add_js_cdn(options.javascript_cdn)
	report.add_css_cdn(options.css_cdn)
	report.build(template)
	report.write(options.output + '.html')
       	

if __name__ == '__main__':
	parse_args()