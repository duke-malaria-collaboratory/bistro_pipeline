# snakefile to run euroformix

# path to config file
config: "config/config.yaml"

# get paths
pop_freqs_csv = config['pop_freqs_csv']
hum_profiles_csv = config['hum_profiles_csv']
moz_profiles_csv = config['moz_profiles']
pop_freqs_rds = re.sub(".csv", ".rds", pop_freqs_csv)
hum_profiles_rds = re.sub(".csv", ".rds", hum_profiles_csv)
with open(moz_profiles_csv) as f:
    next(f)
    moz_ids = [row.split()[0] for row in f]
outfile = config['outfile']

# what we want to output
rule all:
  input:
    expand('results/log10LRs_by_mozzie/{moz_id}_log10LRs.csv', moz_id=moz_ids),
    outfile

# make data in format required for euroformix
rule generate_rds:
  input:
    pop_freqs_csv,
    hum_profiles,
    moz_profiles
  output:
    pop_freqs_rds,
    hum_profiles_rds,
    moz_profiles_rds
  script:
    'scripts/generate_rds.R'

# calculate likelihood ratios (each mosquito gets an output file)
rule calculate_lrs:
  input:
    pop_freqs_rds,
    hum_profiles_rds,
    'data/mozzies/{moz_id}_profile.rds'
  output:
    'results/log10LRs_by_mozzie/{moz_id}_log10LRs.rds'
  script:
    'scripts/calculate_lrs.R'

# combine likelihood ratios for all mosquitoes 
rule combine_output:
  input:
    expand('results/log10LRs_by_mozzie/{moz_id}_log10LRs.csv', moz_id=moz_ids)
  output:
    output
  script:
    'scripts/cobmine_output.R'

rule rm_intermediates:
  input:
    output
  shell:
    'rm -r results/log10LRs_by_mozzie/'
