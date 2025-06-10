#! /usr/bin/env python
import csv, argparse, inspect, pickle, os
import numpy as np
from pets.cohort import Cohort
from pets.parsers.cohort_parser import Cohort_Parser
from py_report_html import Py_report_html
import pandas as pd

##### FUNCTIONS #####

def read_and_aggregate_sims(input_filename, aggregation=max):
	data = {}
	with open(input_filename, 'r') as file:
		for line in file:
			row = line.strip().split('\t')
			paper_id = row[0]
			phenotypes = row[1].split(',')
			similarities = [list(map(float, sim.split(';'))) for sim in row[2].split(',')]

			data[paper_id] = {}
			for phenotype, similarity_list in zip(phenotypes, similarities):
				data[paper_id][phenotype] = aggregation(similarity_list)
	return data


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
parser.add_argument("-N", "--neg_matrix_limits", dest="neg_matrix_limits", default= [20, 40], type= lambda data: [int(i) for i in data.split(",")],
                    help="Number of rows and columns to show in the negative heatmap defined as 'Nrows,Ncols'. Default 20,40")
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
parser.add_argument("--sim", dest="sim", default= None,
                    help="Similarity method to use")
parser.add_argument("--doc_type", dest="doc_type", default= None,
                    help="Similarity method to use")
parser.add_argument("--overwrite_pickle", dest="overwrite_pickle", default= False, action="store_true",
                    help="Overwrite the pickle with results if you do not want to use the cached version (if executed before)")                                        
opts = parser.parse_args()
options = vars(opts)


########### MAIN ###################

pickle_path = os.path.join(options['output_file'].replace(".html", ""), 'tmp')
pickle_filename = os.path.join(pickle_path, 'similitudes.pckl')
if os.path.exists(pickle_filename) and not options['overwrite_pickle']:
    print("Pickle does exist, skipping calculations")
    file = open(pickle_filename, 'rb')
    data = pickle.load(file)
    file.close()
    similarities = data['similarities']
    pubmed_ids_and_titles_dict = data['pubmed_ids_and_titles_dict']
    container = data['container']

else:
    print("Pickle does not exist, doing similarity calculations")
    papers_hpo_sims = read_and_aggregate_sims(options['input_file'], aggregation = max)
    with open(options["pubmed_ids_and_titles"]) as f: pubmed_ids_and_titles = [line.rstrip().split("\t") for line in f]

    hpo_file = options["ontology"]
    Cohort.load_ontology("hpo", hpo_file)
    Cohort.act_ont = "hpo"
    hpo = Cohort.get_ontology(Cohort.act_ont)
    patient_data, _, _ = Cohort_Parser.load(options)
    patient_data.check(hard=options["hard_check"])

    clean_profiles = patient_data.profiles
    ref_profile = hpo.clean_profile_hard(options["ref_prof"])
    #print(ref_profile)
    hpo.load_profiles({"ref": ref_profile}, reset_stored= True)

    candidate_sim_matrix, _, candidates_ids, similarities, candidate_pr_cd_term_matches, candidate_terms_all_sims = hpo.calc_sim_term2term_similarity_matrix(ref_profile, "ref", clean_profiles, 
            term_limit = options["matrix_limits"][0], candidate_limit = options["matrix_limits"][-1], sim_type = options['sim'], bidirectional = False,
            string_format = True, header_id = "HP")

    candidate_terms_all_sims = {candidates_ids[candidate_idx]:canditate_terms_sims for candidate_idx, canditate_terms_sims in candidate_terms_all_sims.items()}
    negative_matrix, _ = hpo.get_negative_terms_matrix(candidate_terms_all_sims, string_format = True, header_id = "HP",
            term_limit = options["neg_matrix_limits"][0], candidate_limit = options["neg_matrix_limits"][-1])

    candidates_sims = [[str(candidate), str(value)] for candidate, value in similarities["ref"].items()]


    ref_profile_phenIDX_and_code = list(enumerate([hpo.translate_name(row[0]) for row in candidate_sim_matrix[1:]]))
    stEngine_sims_table = [[0] * (len(row)-1) for row in candidate_sim_matrix[1:]]

    for paper_index in candidate_pr_cd_term_matches.keys():
        paper_id = candidates_ids[paper_index]
        for prof_phen_idx, profile_phen_code in ref_profile_phenIDX_and_code:
            paper_matched_hpo = candidate_pr_cd_term_matches[paper_index].get(profile_phen_code, None)
            hpo_stengine_sim_raw = papers_hpo_sims[paper_id].get(paper_matched_hpo)
            hpo_stengine_sim = round(hpo_stengine_sim_raw, 2) if hpo_stengine_sim_raw else ""
            stEngine_sims_table[prof_phen_idx][paper_index] = hpo_stengine_sim

    stEngine_sims_table.insert(0, candidates_ids)
    for prof_phen_idx, row in enumerate(stEngine_sims_table): row.insert(0, candidate_sim_matrix[prof_phen_idx][0])


    ##### DOING SOME ADDITIONAL PREPROCESSING TO MAKE TOP50 TABLE BEFORE ADDING THE DATA TO CONTAINER
    upper_limit = options["matrix_limits"][-1]
    candidates_sims.sort(key=lambda row: float(row[1]), reverse=True) 
    candidates_sims = candidates_sims[0:upper_limit]
        
    pubmed_ids_and_sims_df = pd.DataFrame(candidates_sims, columns=["pubmed_id", "similarity"])
    pubmed_ids_and_titles_df = pd.DataFrame(pubmed_ids_and_titles, columns=["pubmed_id", "title", "article-type", "article-category"])

    pubmed_ids_sims_and_titles = pd.merge(pubmed_ids_and_sims_df, pubmed_ids_and_titles_df, on="pubmed_id", how="inner")
    pubmed_ids_sims_and_titles.drop(columns=["article-type", "article-category"], inplace=True) #convert back to a list of lists and add the header back
    pubmed_ids_sims_and_titles["similarity"] = pubmed_ids_sims_and_titles["similarity"].astype(float).round(2)
    pubmed_ids_sims_and_titles["pubmed_id"] = pubmed_ids_sims_and_titles["pubmed_id"].apply(lambda pmid: f"<a href=https://pubmed.ncbi.nlm.nih.gov/{pmid}>{pmid}</a>")
    supp_info = pubmed_ids_sims_and_titles.values.tolist()
    supp_info.insert(0, ["pubmed_id", "similarity", "title"])

    pubmed_ids_and_titles_dict = {row[0]: row[1] for row in pubmed_ids_and_titles}

    container = { "similarity_matrix": candidate_sim_matrix, 
                "negative_matrix": negative_matrix, 
                "candidates_sims": candidates_sims,
                "pubmed_ids_and_titles": pubmed_ids_and_titles,
                "stEngine_sims_table": stEngine_sims_table,
                "disease": options["disease_name"],
                "ont_sim_method": options['sim'],
                "supp_info": supp_info,
                "doc_type": options["doc_type"]}
    
    pickle_obj = {'container': container,
                  'similarities': similarities,
                  'pubmed_ids_and_titles_dict': pubmed_ids_and_titles_dict}
    os.makedirs(pickle_path, exist_ok = True)
    file = open(pickle_filename, 'wb')
    pickle.dump(pickle_obj, file)
    file.close()


#MAKING EACH RASOPATHY HEATMAPS REPORT

template = open(options["template"]).read()
report = Py_report_html(container, f'Similarity matrix for {options["disease_name"]}', data_from_files=True)
report.build(template)
report.write(options["output_file"])


#WRITING TABLES FOR AGGREGRATED TOP 10 AND SINGLE TOP50 LATEX TABLES FOR EACH RASOPATHY

apply_bold = lambda text: f'\\textbf{{{text}}}'
keywords = ["noonan", "cfc", "cardiofaciocutaneous", "cardiofacio-cutaneous", "cardio-facio-cutaneous", "costello", "nf1", "nf-1", "neurofibromatosis",
	    "rare disease", "rasopathy", "rasopathies", "leopard", "watson", "legius"] 

top = 1
with open(options["output_file"].replace('.html','.txt'), 'w') as f:
        for candidate, value in sorted(similarities["ref"].items(), key=lambda pair: pair[1], reverse=True):
                candidate_title = pubmed_ids_and_titles_dict.get(candidate, "None")				
                f.write("\t".join([str(candidate), str(top), str(value), candidate_title])+"\n")
                top += 1

top = 1				
with open(options["output_file"].replace('.html','_latex.txt'), 'w') as f:
        for candidate, value in sorted(similarities["ref"].items(), key=lambda pair: pair[1], reverse=True):
                candidate_title = pubmed_ids_and_titles_dict.get(candidate, "None").replace("_", "\\_")
                for kw in keywords: candidate_title = candidate_title.replace(kw, apply_bold(kw))
                value = round(value, 2)
                f.write(" & ".join([str(top), str(candidate), str(value), candidate_title])+"\\\\ \\hline\n")
                top += 1