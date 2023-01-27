# snakefile to run euroformix

# imports
import re
import csv

# path to config file
configfile: "config/config.yaml"

# get paths
hu_allele_freqs_csv = config['hu_allele_freqs_csv']
hum_profiles_csv = config['hum_profiles_csv']
moz_profiles_csv = config['moz_profiles_csv']
hum_profiles_formatted = 'output/' + re.sub(".csv", "_formatted.csv", hum_profiles_csv)
moz_profiles_formatted = 'output/' + re.sub(".csv", "_formatted.csv", moz_profiles_csv)
hu_allele_freqs_rds = 'output/' + re.sub(".csv", ".rds", hu_allele_freqs_csv)
hum_profiles_rds = re.sub("_formatted.csv", ".rds", hum_profiles_formatted)
outfile = config['outfile']
kit = config['kit']
threads = config['threads']

# get mozzie ids
with open(moz_profiles_csv) as f:
    next(f)
    reader = csv.reader(f, delimiter=',')
    moz_ids = set([row[0] for row in reader])

# what we want to output
rule all:
  input:
    outfile

# subset to mozzies we want to analyze
rule format_input_csvs:
  input:
    hum_profiles_csv,
    moz_profiles_csv
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
rule calc_logLR:
  input:
    hu_allele_freqs_rds,
    hum_profiles_rds,
    moz_profiles_csv,
    'output/data/mozzies/{moz_id}_profile.rds'
  params:
    kit,
    threads
  output:
    'output/log10LRs_by_mozzie/{moz_id}_log10LRs.csv'
  script:
    'scripts/calc_logLR.R'

# combine likelihood ratios for all mosquitoes 
rule combine_output:
  input:
    expand('output/log10LRs_by_mozzie/{moz_id}_log10LRs.csv', moz_id=moz_ids)
  output:
    outfile
  script:
    'scripts/combine_output.R'

