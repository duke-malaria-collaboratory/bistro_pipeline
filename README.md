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
