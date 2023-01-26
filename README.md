# Snakemake pipeline to run [euroformix](https://github.com/oyvble/euroformix)

This snakemake pipeline takes csvs with:
1. Population allele frequency.
1. Human STR profiles (the "reference").
1. Mosquito STR profiles (the "evidence").
And outputs a dataframe with log10 likelihood ratios of being a match for each mosquito-human pair.  

## More information about euroformix
- Manuscript: [EuroForMix: An open source software based on a continuous model to evaluate STR DNA profiles from a mixture of contributors with artefacts](https://pubmed.ncbi.nlm.nih.gov/26720812/)
- [GitHub](https://github.com/oyvble/euroformix)
- [Website that explains GUI](http://www.euroformix.com/)

## Data requirements

Formats for each dataset required for this pipeline are shown below.

### Population allele frequency

Population frequencies for each allele at each locus should be supplied in a .csv file with one column for each STR marker and one row for each allele. The alleles should be listed in a column titled "Allele". The first two rows of an example table with the loci from the Promega Geneprint10 kit is shown below:

| Allele | TH01 | D21S11 | D5S818 | D13S317 | D7S820 | D16S539 | CSF1PO | AMEL | vWA | TPOX |
|:------:|:----:|:------:|:------:|:-------:|:------:|:------:|:----:|:---:|:----:|:---:|
|6|0.206957| | | | | | | | |0.098276|
|8|0.250435| |0.06117|0.021053|0.187716|0.033304|0.042205| | |0.24569|


### Human STR profiles (the "reference")

The human reference STR profiles should be supplied in a .csv file with one row per STR marker for each person. The column headings should be formmated as shown in the example rows below:

|SampleName|Marker|Allele1|Allele2|
|:---:|:---:|:---:|:---:|
|Person_1|TH01|6|8|
|Person_1|D21S11|29|30|


### Mosquito STR profiles (the "evidence")

The mosquito STR profiles (evidence samples) should be supplied in a .csv file with one rwo per STR marker for each sample. The column headings should be formatted as shown in the example rows below:

|SampleName|Marker|Allele1|Allele2|Allele3|Allele4|...|Height1|Height2|Height3|Height4|...|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Sample_1|TH01|6|8|9| | |4887|4662|9104| | |
|Sample_1|D21S11|27|28|30| | |4402|8325|2181| | |


## Installing euroformix

First, [download miniconda](https://docs.conda.io/en/latest/miniconda.html) for linux if you don't already have it:
```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh
```

Next, create the euroformix conda environment and install euroformix from GitHub, which you only have to do once:
```
mamba env create -f config/euroformix.yml
Rscript -e "devtools::install_github('https://github.com/oyvble/euroformix.git')"
```

To activate the conda environment, which you have to do each time:
```
conda activate euroformix 
```

## Using the euroformix snakemake pipeline

Useful snakemake arguments (see below for more on snakemake):
- `snakemake -n` dry-run (to test it out before running it)
- `snakemake` runs the pipeline
- ` snakemake --dag | dot -Tsvg > dag.svg` creates a dag (this can be super difficult to read with large complex pipelines)

To run the pipeline on the cluster, you have to modify:
- `euroformix.sbat` (email address)
- `config/cluster.yml` (email address)
- `config/config.yml` (paths to data; possibly other parameters)

Then run:
```
conda activate euroformix # activate the conda environment
sbatch euroformix.sbat # submit the job to the cluster
```

## Learning more about snakemake

Benefits of snakemake
- Your analysis is reproducible.
- You don't have to re-perform computationally intensive tasks early in the pipeline to change downstream analyses or figures.
- You can easily combine shell, R, python, etc. scritps into one pipeline.
- You can easily share your pipeline with others.
- You can submit a single slurm job and snakemake handles submitting the rest of your jobs for you.

Useful links to learn more about snakemake
- [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/)
- [Short overview](https://slides.com/johanneskoester/snakemake-short#/)
- [More detailed overview](https://slides.com/johanneskoester/snakemake-tutorial#/)
