#! /usr/bin/env python
import argparse, os, glob, sys
import pandas as pd
from collections import defaultdict

#from this ---- pmid, rank, sim, title
#to this ------- pmid & MeanRank, title, Noonan Rank, NF Rank, Costello Rank, CFC Rank
#################################################################################
## METHODS
#################################################################################

def check_rasopathy(file, rasopaties_to_use):
    for raso in rasopaties_to_use:
        if raso in file:
            return True
    return False

def give_title(df, pmid):
    if not pd.isna(df.at[pmid, 'title0']):
        return df.at[pmid, 'title0']
    elif not pd.isna(df.at[pmid, 'title1']):
        return df.at[pmid, 'title1']
    elif not pd.isna(df.at[pmid, 'title2']):
        return df.at[pmid, 'title2']
    elif not pd.isna(df.at[pmid, 'title3']):
        return df.at[pmid, 'title3']
    else:
        raise ValueError(f'No title found for pmid {pmid}')

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-t", "--top_n", dest="top_n", default= 10, type=int, 
                    help="Flag to choose the first N items of each of the rasopathies to choose")

parser.add_argument("-f", "--topn_folder", dest="topn_folder", default= None,
                    help="Path to the folder with the top10 documents of each rasopathy")

parser.add_argument("-r", "--rasopaties_to_use", dest="rasopaties_to_use", default= None, type=lambda terms: terms.split(','),
                    help="Comma separated list of rasopaties to use")

parser.add_argument("-o", "--output_file", dest="output_file", default= None,
                    help="Output file with the aggregated table")

opts = parser.parse_args()
options = vars(opts)

#################################################################################
## MAIN
#################################################################################

top10_files = [file for file in glob.glob(f'{options["topn_folder"]}/*.txt') if check_rasopathy(file, options['rasopaties_to_use'])]
first = True
rasopaties_top50_ranks=defaultdict(dict)
disease_names = []

counter = 0
for raso_top10 in top10_files:
    #print(f'Processing {raso_top10}')
    disease_name = os.path.basename(raso_top10).split('_')[0]
    disease_names.append(disease_name)
    disease_data = defaultdict(list)
    with open(raso_top10) as f:
        for idx, line in enumerate(f):
            pmid, rank, sim, title = line.strip().split('\t')
            rasopaties_top50_ranks[disease_name][pmid] = int(rank)
            if idx < options['top_n']:
                disease_data['pmid'].append(pmid)
                disease_data['title'].append(title)
                disease_data[f'{disease_name}_rank'].append(int(rank))
                disease_data[f'{disease_name}_similarity'].append(float(sim))
    if first:
        df = pd.DataFrame(disease_data)
        first = False
    else:
        df = df.merge(pd.DataFrame(disease_data), on='pmid', how='outer',  suffixes=(str(counter), str(counter+1)) )
        counter += 1


#Set pmid column as index
df = df.set_index('pmid')


#Fill NaN values with top50 rank or 50 if not found and create a title column prefilled with empty strings
df['title'] = ''
for disease_name in disease_names:
    for pmid in df.index:
        if pd.isna(df.at[pmid, f'{disease_name}_rank']):
            df.at[pmid, f'{disease_name}_rank'] = rasopaties_top50_ranks[disease_name].get(pmid, 50.01)
            df.at[pmid, "title"] = give_title(df, pmid)


#Calculate MeanRank
ranks_cols = [disease for disease in df.columns if '_rank' in disease]
sim_cols = [disease for disease in df.columns if '_similarity' in disease]
df['MeanRank'] = df[ranks_cols].mean(axis=1)
#Change all cells with value of 50.01 to X
df.replace(50.01, "X", inplace=True)
df[ranks_cols] = df[ranks_cols].applymap(lambda num: int(num) if num != "X" else num)
#Sort by MeanRank descending
df = df.sort_values(by='MeanRank', ascending=True)
#Round values of ranks
df = df.round({'MeanRank': 2})
#Drop individual similarities columns
df = df.drop(columns=sim_cols)
#Drop individual titles columns
df = df.drop(columns=['title0', 'title1', 'title2', 'title3'])
#Reorder columns to show pmid, meanrank, title, Noonan Rank, NF Rank, Costello Rank, CFC Rank
df = df[['MeanRank', 'title', "noonan_rank", "nf_rank", "costello_rank", "cfc_rank"]]
#Save to file
df.to_csv(options['output_file'], sep='\t', index=True)