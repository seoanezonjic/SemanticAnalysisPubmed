#! /usr/bin/env python

import argparse
import inspect
from pets.cohort import Cohort
from pets.parsers.cohort_parser import Cohort_Parser
from py_report_html import Py_report_html

##### OPT PARSE #####
parser = argparse.ArgumentParser(description=f'Usage: {inspect.stack()[0][3]} [options]')
parser.add_argument("-H", "--header", dest="header", default= True, action="store_false",
                        help="Set if the file has a line header. Default true")
parser.add_argument("-x", "--sex_col", dest="sex_col", default= None,
                    help="Column name if header is true, otherwise 0-based position of the column with the patient sex")
parser.add_argument("-S", "--hpo_separator", dest="separator", default='|',
                    help="Set which character must be used to split the HPO profile. Default '|'")
parser.add_argument("-d", "--pat_id_col", dest="id_col", default= None,
                        help="Column name if header is true, otherwise 0-based position of the column with the patient id")
parser.add_argument("-o", "--output_file", dest="output_file", default= 'report.html',
                    help="Output paco file with HPO names")
parser.add_argument("-P", "--input_file", dest="input_file", default= None,
                    help="Input file with PACO extension")
parser.add_argument("-f", "--general_prof_freq", dest="term_freq", default= 0, type= int,
                    help="When reference profile is not given, a general ine is computed with all profiles. If a freq is defined (0-1), all terms with freq minor than limit are removed")
parser.add_argument("-L", "--matrix_limits", dest="matrix_limits", default= [20, 40], type= lambda data: [int(i) for i in data.split(",")],
                    help="Number of rows and columns to show in heatmap defined as 'Nrows,Ncols'. Default 20,40")
parser.add_argument("-r", "--ref_profile", dest="ref_prof", default= None, 
                    type = lambda file: [line.strip() for line in open(file).readlines()],
                    help="Path to reference profile. One term code per line")
parser.add_argument("-p", "--hpo_term_col", dest="ont_col", default= None,
                    help="Column name if header true or 0-based position of the column with the HPO terms")
parser.add_argument("-e", "--end_col", dest="end_col", default= None,
                    help="Column name if header is true, otherwise 0-based position of the column with the end mutation coordinate")
parser.add_argument("--hard_check", dest="hard_check", default= True, action="store_false",
                    help="Set to disable hard check cleaning. Default true") 
parser.add_argument("-O", "--ontology", dest="ontology", default= None,
                    help="Path to ontology file")
parser.add_argument("-t", "--template", dest="template", default= None,
                    help="Path to template file")
parser.add_argument("--pubmed_ids_and_titles", dest="pubmed_ids_and_titles", default= None,
                    help="Path to pubmed_ids_and_titles file")
parser.add_argument("--disease_name", dest="disease_name", default= None,
                    help="Name of the disease for the report")
opts = parser.parse_args()
options = vars(opts)


########### MAIN ###################

with open(options["pubmed_ids_and_titles"]) as f:
    pubmed_ids_and_titles = [line.rstrip().split("\t") for line in f]

hpo_file = options["ontology"]
Cohort.load_ontology("hpo", hpo_file)
Cohort.act_ont = "hpo"
hpo = Cohort.get_ontology(Cohort.act_ont)
patient_data, _, _ = Cohort_Parser.load(options)
patient_data.check(hard=options["hard_check"])

clean_profiles = patient_data.profiles
ref_profile = hpo.clean_profile_hard(options["ref_prof"])
hpo.load_profiles({"ref": ref_profile}, reset_stored= True)

candidate_sim_matrix, _, candidates_ids, similarities = hpo.calc_sim_term2term_similarity_matrix(ref_profile, "ref", clean_profiles, 
        term_limit = options["matrix_limits"][0], candidate_limit = options["matrix_limits"][-1], sim_type = 'lin', bidirectional = False,
        string_format = True, header_id = "HP")

negative_matrix, _ = hpo.get_negative_terms_matrix(ref_profile, clean_profiles, candidate_ids = candidates_ids, 
        term_limit = options["matrix_limits"][0], candidate_limit = options["matrix_limits"][-1],
        string_format = True, header_id = "HP")

candidates_sims = [[str(candidate), str(value)] for candidate, value in similarities["ref"].items()]

template = open(options["template"]).read()

container = { "similarity_matrix": candidate_sim_matrix, 
             "negative_matrix": negative_matrix, 
             "candidates_sims": candidates_sims,
             "pubmed_ids_and_titles": pubmed_ids_and_titles,
             "disease": options["disease_name"]}

report = Py_report_html(container, f'Similarity matrix for {options["disease_name"]}')
report.build(template)
report.write(options["output_file"])