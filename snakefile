# snakefile to run BISTRO

# imports
import re
import csv

# path to config file
configfile: "config/config.yaml"

# get paths
bm_profiles_csv = config['bm_profiles_csv']
hum_profiles_csv = config['hum_profiles_csv']
hum_allele_freqs_csv = config['hum_allele_freqs_csv']
hum_profiles_formatted = 'output/data/' + re.sub('.csv', '_formatted.csv', re.sub('.*/', '', hum_profiles_csv))
bm_profiles_formatted = 'output/data/' + re.sub('.csv', '_formatted.csv', re.sub('.*/', '', bm_profiles_csv))
lr_outfile = config['lr_outfile']
match_outfile = config['match_outfile']
kit = config['kit']
peak_thresh = config['peak_thresh']
rm_twins = config['rm_twins']
model_degrad = config['model_degrad']
model_bw_stutt = config['model_bw_stutt']
model_fw_stutt = config['model_fw_stutt']
difftol = config['difftol']
threads = config['threads']
seed = config['seed']
time_limit = config['time_limit']


# get bloodmeal ids
with open(bm_profiles_csv) as f:
    next(f)
    reader = csv.reader(f, delimiter=',')
    bm_ids = set([row[0] for row in reader])

# what we want to output
rule all:
  input:
    expand('output/log10LRs_by_bloodmeal/{bm_id}_log10LRs.csv', bm_id=bm_ids),
    lr_outfile,
    match_outfile

# calculate human population allele frequencies if needed
if hum_allele_freqs_csv == 'None':
  print('Calculating human population allele frequencies from human profiles')
  hum_allele_freqs_csv = 'output/data/' + re.sub(".csv", "_allele_freqs.csv", re.sub('.*/', '', hum_profiles_csv))

  rule get_hum_allele_freqs:
    input:
      hum_profiles_csv
    output:
      hum_allele_freqs_csv
    script:
      'scripts/get_hum_allele_freqs.R'

# calculate likelihood ratios (each bloodmeal gets an output file)
rule calc_log10LR:
  input:
    hum_allele_freqs_csv=hum_allele_freqs_csv,
    hum_profiles_csv=hum_profiles_csv,
    bm_profiles_csv=bm_profiles_csv,
  params:
    kit=kit,
    peak_thresh=peak_thresh,
    rm_twins=rm_twins,
    difftol=difftol,
    threads=threads,
    seed=seed,
    time_limit=time_limit,
    model_degrad=model_degrad,
    model_bw_stutt=model_bw_stutt,
    model_fw_stutt=model_fw_stutt
  output:
    'output/log10LRs_by_bloodmeal/{bm_id}_log10LRs.csv'
  script:
    'scripts/calc_log10LR.R'

# identify matches between bloodmeals and humans
rule identify_matches:
  input:
    'output/log10LRs_by_bloodmeal/{bm_id}_log10LRs.csv'
  output:
    'output/matches_by_bloodmeal/{bm_id}_matches.csv'
  script:
    'scripts/identify_matches.R'

# combine likelihood ratios for all bloodmeals
rule combine_lr_output:
  input:
    expand('output/log10LRs_by_bloodmeal/{bm_id}_log10LRs.csv', bm_id=bm_ids)
  output:
    lr_outfile
  script:
    'scripts/combine_output.R'

# combine likelihood ratios for all bloodmeals
rule combine_match_output:
  input:
    expand('output/matches_by_bloodmeal/{bm_id}_matches.csv', bm_id=bm_ids)
  output:
    match_outfile
  script:
    'scripts/combine_output.R'
