# BISTRO: Blood meal Identification by STR Overlap

This snakemake pipeline identifies matches between mosquitoes (the "evidence") and the people they bit (the "reference") using short tandem repeat (STR) profiles of human blood from freshly fed mosquitoes and from people.

Inputs:
1. Human STR profiles (the "reference")
1. Mosquito STR profiles (the "evidence")
1. Human population allele frequencies (optional)

Outputs:
1. log10LRs for each mosquito-human pair
1. Human matches for each mosquito

See below for more information about the format of the input and output files. 

## The pipeline

The pipline executes the following steps:
1. If no human population allele frequencies are provided, calculates these frequencies from the human STR profiles. 
1. Removes STR profiles from the human database that occur more than once (likely twins). These are not used to identify mosquito-human pairs because matches with these people cannot be resolved. 
1. Estimates the number of contributors (NOC) for each mosquito based on the maximum number of distinct alleles identified at a given locus: ceiling(max(number of alleles)/2). This is the minimum NOC. 
1. Calculates log10 likelihood ratios (log10LRs) for each mosquito-human pair using the `contLikSearch` function from `euroformix`. Degradation is modeled, but forward and backward stutter are not. The numerator of the log10LR is the likelihood that the person was bitten by the mosquito and the denominator is the likelihood that someone else was bitten by the mosquito. 
1. Uses the log10LRs and estimated NOCs to identify likely human contributors for each mosquito. 

The core of the pipeline is the [`contLikSearch()`](https://github.com/oyvble/euroformix/blob/master/R/contLikSearch.R) function from the `euroformix` package. Here is more information about euroformix: 
- Manuscript: [EuroForMix: An open source software based on a continuous model to evaluate STR DNA profiles from a mixture of contributors with artefacts](https://pubmed.ncbi.nlm.nih.gov/26720812/)
- [GitHub](https://github.com/oyvble/euroformix)
- [Website that explains GUI](http://www.euroformix.com/)

## Data requirements

Formats for each dataset required for this pipeline are shown below.

### Human STR profiles (the "reference")

The human reference STR profiles should be supplied in a csv file with one row per allele for each person and marker. The column headings should be formmated as shown in the example rows below:

|SampleName|Marker|Allele|
|:---:|:---:|:---:|
|Person_1|TH01|6|
|Person_1|TH01|8|
|Person_1|D21S11|29|
|Person_1|D21S11|30|

### Mosquito STR profiles (the "evidence")

The mosquito STR profiles (evidence samples) should be supplied in a csv file with one row per allele for each mosquito and marker. You must also provide the peak height for each allele. The column headings should be formatted as shown in the example rows below:

|SampleName|Marker|Allele|Height|
|:---:|:---:|:---:|:---:|
|Sample_1|TH01|6|4887|
|Sample_1|TH01|9|4662|

### Human population allele frequencies (optional)

Human population frequencies for each allele at each locus can be supplied in a csv file. If no csv file is provided, population allele frequencies will be computed from the human STR profiles. 

If you would like to input population allele frequencies, the csv file should contain one column for each STR marker and one row for each allele. The alleles should be listed in a column titled "Allele". The first two rows of an example table with the loci from the Promega Geneprint10 kit is shown below:

| Allele | TH01 | D21S11 | D5S818 | D13S317 | D7S820 | D16S539 | CSF1PO | AMEL | vWA | TPOX |
|:------:|:----:|:------:|:------:|:-------:|:------:|:------:|:----:|:---:|:----:|:---:|
|6|0.206957| | | | | | | | |0.098276|
|8|0.250435| |0.06117|0.021053|0.187716|0.033304|0.042205| | |0.24569|


## Installing dependencies

First, [download miniconda](https://docs.conda.io/en/latest/miniconda.html) for linux if you don't already have it:
```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh
```

Next, run these commands to download and install the pipeline and the euroformix R package (you only have to do all this once):
```
git clone https://github.com/duke-malaria-collaboratory/bistro.git # download this GitHub repository
cd bistro # move into the bistro directory
mamba env create -f config/environment/bistro.yaml # create the bistro conda environment
conda activate bistro # activate the bistro conda environment
Rscript -e "devtools::install_github('https://github.com/oyvble/euroformix.git')" # install euroformix in environment
```

Note that you will have to activate the conda environment each time you open a new terminal:
```
conda activate bistro
```

## Using the bistro snakemake pipeline

To run the pipeline on the cluster, you have to modify the following files:
- `scripts/submit_slurm.sbat` (email address)
- `config/slurm/cluster.yaml` (email address)
- `config/config.yaml` (paths to input data; other parameters such as the kit if needed)

To check to see if everything is working okay, first do a "dry-run":
```
conda activate bistro # be sure you've activated the environment! 
snakemake -n # dry-run
```

If this runs successfully, then run:
```
sbatch scripts/submit_slurm.sbat # submit the job to the cluster
```

See below for more information on snakemake.

## Output files

The main output is a csv file containing which humans matched to each mosquito. By default, this output is stored in `output/matches.csv`. Here is an example output:

|sample_evidence|min_noc|m_locus_count|match|sample_reference|log10LR|note|thresh_low|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Sample_1|0|0|No|NA|NA|No peaks|1|
|Sample_2|1|10|Yes|Person_1|10.91|Passed all filters|10|

The columns contain:
- `sample_evidence`: mosquito sample ("evidence")
- `min_noc`: minimum NOC of the mosquito sample
- `m_locus_count`: number of loci STR-typed in the mosquito
- `match`: whether the mosquito STR profile matched to a human in the database
- `sample_reference`: human match for the mosquito
- `log10LR`: log10LR of the mosquito-human match
- `note`: why the mosquito does or doesn't have a match
- `thresh_low`: log10LR threshold at which the match was made

The other main output file is a csv file containing the log10LR for each mosquito-human pair that can be used to investigate why matches were or were not called for a specific mosquito. By default, this output is stored in `output/log10LRs.csv`. The numerator of the log10LR is the likelihood that the person was bitten by the mosquito and the denominator is the likelihood that someone else was bitten by the mosquito. 

Intermediate data files generated by the pipeline include formatted input files, a file with human population allele frequencies (if calculated from the human STR profiles), rds files with the data shaped in the format required for `euroformix`, and log10LR and match files for each individual mosquito. 

## Learning more about snakemake

Benefits of snakemake:
- Your analysis is reproducible.
- You don't have to re-perform computationally intensive tasks early in the pipeline to change downstream analyses or figures.
- You can easily combine shell, R, Python, etc. scritps into one pipeline.
- You can easily share your pipeline with others.
- You can submit a single slurm job and snakemake handles submitting the rest of your jobs for you.

Useful links to learn more about snakemake:
- [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/)
- [Short overview](https://slides.com/johanneskoester/snakemake-short#/)
- [More detailed overview](https://slides.com/johanneskoester/snakemake-tutorial#/)
