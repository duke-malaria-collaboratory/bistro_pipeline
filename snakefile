# snakefile to run euroformix

# imports
import re
import csv

# path to config file
configfile: "config/config.yaml"

# get paths
hum_profiles_csv = config['hum_profiles_csv']
moz_profiles_csv = config['moz_profiles_csv']
hum_allele_freqs_csv = config['hum_allele_freqs_csv']
hum_profiles_formatted = 'output/' + re.sub(".csv", "_formatted.csv", hum_profiles_csv)
moz_profiles_formatted = 'output/' + re.sub(".csv", "_formatted.csv", moz_profiles_csv)
min_noc_csv = 'output/data/min_noc.csv'
hu_allele_freqs_rds = re.sub(".csv", ".rds", hu_allele_freqs_csv)
hum_profiles_rds = re.sub("_formatted.csv", ".rds", hum_profiles_formatted)
lr_outfile = config['lr_outfile']
match_outfile = config['match_outfile']
kit = config['kit']
threshT = config['threshT']
difftol = config['difftol']
threads = config['threads']
seed = config['seed']
time_limit = config['time_limit']

# get mozzie ids
with open(moz_profiles_csv) as f:
    next(f)
    reader = csv.reader(f, delimiter=',')
    moz_ids = set([row[0] for row in reader])

# what we want to output
rule all:
  input:
    lr_outfile,
    match_outfile

# calculate human population allele frequencies if needed
if hum_allele_freqs_csv is None:
  hum_allele_freqs_csv = 'output/' + re.sub(".csv", "_allele_freqs.csv", hum_profiles_csv)

  rule get_hum_allele_freqs:
    input:
      hum_profiles_csv
    output:
      hum_allele_freqs_csv
    script:
      'scripts/get_hum_allele_freqs.R' 

# get minimum number of contributors for each mosquito
rule get_min_nocs:
  input:
    moz_profiles_csv
  output:
    min_noc_csv
  script:
    'scripts/get_min_nocs.R'

# subset to mozzies we want to analyze
rule format_input_csvs:
  input:
    hum_profiles_csv,
    moz_profiles_csv,
  params: 
    threshT
  output:
    hum_profiles_formatted,
    moz_profiles_formatted
  script:
    'scripts/format_input_csvs.R'

# make data in format required for euroformix
rule shape_str_data:
  input:
    hu_allele_freqs_csv,
    hum_profiles_formatted,
    moz_profiles_formatted,
    moz_profiles_csv
  output:
    hu_allele_freqs_rds,
    hum_profiles_rds,
    expand('output/data/mozzies/{moz_id}_profile.rds', moz_id=moz_ids)
  script:
    'scripts/shape_str_data.R'

# calculate likelihood ratios (each mosquito gets an output file)
rule calc_log10LR:
  input:
    hu_allele_freqs_rds,
    hum_profiles_rds,
    moz_profiles_formatted,
    min_noc_csv,
    'output/data/mozzies/{moz_id}_profile.rds'
  params:
    kit=kit,
    threshT=threshT,
    difftol=difftol,  
    threads=threads,
    seed=seed,
    time_limit=time_limit
  output:
    'output/log10LRs_by_mozzie/{moz_id}_log10LRs.csv'
  script:
    'scripts/calc_log10LR.R'

# identify matches between mosquitoes and humans
rule identify_matches:
  input:
    'output/data/mozzies/{moz_id}_profile.rds'
  output:
    'output/matches_by_mozzie/{moz_id}_matches.rds'

# combine likelihood ratios for all mosquitoes 
rule combine_output:
  input:
    expand('output/log10LRs_by_mozzie/{moz_id}_log10LRs.csv', moz_id=moz_ids)
  output:
    lr_outfile
  script:
    'scripts/combine_output.R'

# combine likelihood ratios for all mosquitoes 
rule combine_output:
  input:
    expand('output/matches_by_mozzie/{moz_id}_matches.csv', moz_id=moz_ids)
  output:
    match_outfile
  script:
    'scripts/combine_output.R'
