# MIRACUM-Pipe-docker

This repo offers a framework to easily work with the dockerized version of [MIRACUM-Pipe](https://github.com/AG-Boerries/MIRACUM-Pipe)

## Disclaimer

MIRACUM-Pipe is intended for research use only and not for patient treatment, diagnosis and/or medical records!

## Citation

If you use this repositors please cite:
[![DOI](https://zenodo.org/badge/200218138.svg)](https://zenodo.org/badge/latestdoi/200218138)

## Setup and installation

In order to run the miracum pipeline, one needs to setup tools and databases which we are not allowed to ship due to license issues.
We prepared this project in a way which allows you to easily add the specific components into the pipeline.
Prior running the setup script, some components need to be installed manually:

- tools
  - [annovar](https://annovar.openbioinformatics.org/en/latest/user-guide/download/)

- databases
  - [hallmark gene-sets](http://software.broadinstitute.org/gsea/msigdb/)
    - h.all.vX.X.entrez.gmt (current release is v7.4 (July 2021))
  - [condel score](https://bbglab.irbbarcelona.org/fannsdb/)
    - fannsdb.tsv.gz
    - fannsdb.tsv.gz.tbi
  - [OncoKB](https://www.oncokb.org)
    - Actionalbe Genes, file: oncokb_biomarker_drug_associations.tsv
    - Cancer Genes, file: cancerGeneList.tsv

For running MIRACUM-Pipe the hallmark gene-sets, download link above, need to be formated as a list and stored in a RData file. Inside the `setup.sh` we provide a R script performing the necessary steps. Therefore, a working [R](https://cran.r-project.org/web/packages/GSA/index.html) togther with the R package [GSA](https://cran.r-project.org/web/packages/GSA/index.html) has to be installed.

For the tool annovar you need the download link. Follow the url above and request the link by filling out the form. They will send you an email.
While `setup.sh` is running you'll be asked to enter this download link. Alternatively you could also install annovar by manually extracting it into the folder `tools`.
To install the databases follow the links, register and download the listed files. Just place them into the folder `databases` of your cloned project.

Next, run the setup script. We recommend to install everything, which does **not** include the example and reference data. There are also options to install and setup parts:

```bash
./setup.sh -t all -m /path/to/h.all.v.7.1.entrez.gmt
```

See `setup.sh -h` to list the available options. By default, we do not install the reference genome as well as our example. If you want to install it run

```bash
# download and setup reference genome
./setup.sh -t ref

# download and setup example data
./setup.sh -t example
```

- annotation rescources for annovar
  - create a database for the latest COSMIC release (according to the [annovar manual](http://annovar.openbioinformatics.org/en/latest/user-guide/filter/#cosmic-annotations))
    - Download [prepare_annovar_user.pl](http://www.openbioinformatics.org/annovar/download/prepare_annovar_user.pl) and add to annovar folder
  - register at [COSMIC](https://cancer.sanger.ac.uk/cosmic);
    - Download the latest release for GRCh37 (as of July 2021 the latest release is v94):
      - VCF/CosmicCodingMuts.vcf.gz
      - VCF/CosmicNonCodingVariants.vcf.gz
      - CosmicMutantExport.tsv.gz
      - CosmicNCV.tsv.gz
    - unzip all archives
  - commands to build the annovar database
  
    ```bash
    perl tools/annovar/prepare_annovar_user.pl -dbtype cosmic CosmicMutantExport.tsv -vcf CosmicCodingMuts.vcf > tools/annovar/humandb/hg19_cosmic_coding.txt
    perl prepare_annovar_user.pl -dbtype cosmic CosmicNCV.tsv -vcf CosmicNonCodingVariants.vcf > tools/annovar/humandb/hg19_cosmic_noncoding.txt
    ```

  - Move both created files to the annovar/humandb folder.

## How to configure and run it

The project structure is as follows:

```shell
.
├── assets
│   └── input
│   └── output
│   └── reference
├── conf
│   └── custom.yaml
├── databases
├── tools
├── LICENSE
├── miracum_pipe.sh
├── README.md
└── setup.sh
```

There are three levels of configuration:

- the docker file ships with [default.yaml](https://github.com/AG-Boerries/MIRACUM-Pipe/blob/master/conf/default.yaml) which is setup with default config parameters
- `conf/custom.yaml` contains settings for the entire runtime environment and overwrites `default.yaml`'s values
- In each patient directory one a `patient.yaml` can be created in which every setting of the other two configs can be overwritten.

### Setting up a patient

It is intended to create a patient folder in `input` for each patient containing `patient.yaml`. Further, we recommend to define in it at least the following parameters:

```yaml
sex: XX # or XY
annotation:
  germline: yes # default is no; annotation of germline findings
protocol: wes # possible values are either wes for whole exome sequencing, requires a tumor and matched germline sample, panel for tNGS or tumorOnly for tumor only analysis, only the tumor samples is necessary.
```

#### Example for whole-exome sequencing; protocol parameter: wes

Place the germline R1 and R2 files as well as the tumor files (R1 and R2) into the *input* folder. Either name them `germline_R{1/2}.fastqz.gz` and `tumor_R{1/2}.fastq.gz` or adjust your `patient.yaml` accordingly:

```yaml
[..]
common:
  files:
    tumor_R1: tumor_R1.fastq.gz
    tumor_R2: tumor_R2.fastq.gz
    germline_R1: germline_R1.fastq.gz
    germline_R2: germline_R2.fastq.gz
  protocol: wes
```

#### Example for tNGS; protocol paramter: panel

Place all the tumor DNA files (R1 and R2) into the *input* folder. Additionally, add all tumor RNA files to a dedicated RNA folder. The pipeline currently assumes that you provide 4 files per "direction" i.e., R1 and R2 respectively. Adjust your `patient.yaml` accordingly:

```yaml
[..]
common:
  files:
    # base filenames of the input files, e.g. sample_ID_DNA_S7_L00 for sample_ID_DNA_S7_L001_R1_001.fastq.gz, and provide the number of paired-end files, i.e. only give the number for one direction (R1 or R2)
    panel:
        tumor: MT21-28037-DNA_S7_L00
        numberOfFiles: 4
  entity: ESCA
  RNA:
    # folder contatining RNA fastq files for RNA fusions
    folder: RNA
  protocol: panel
```

Additionally, a non-matching normal BAM file is required for sequenza to work. If you don't analyse all the chromosomes you have to adjust the `chromosomes` entry accordingly.

```yaml
[..]
sequenza:
  # define sequenza-utils parameter
  # --window WINDOW; Window size used for binning the original seqz file. Default is 50.
  window: 50
  # if used for samples without mathcing normal as control a separate non-matching-normal file in bam format is needed;
  # file should be stored in references/sequenza
  nonMatchingNormal: non_matching_normal.bam
  chromosomes: chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX
```

#### Example for tumor only analysis; protocol parameter: tumorOnly

Place the tumor files (R1 and R2) into the *input* folder. Adjust your `patient.yaml` accordingly:

```yaml
[..]
common:
  files:
      # filenames of the input files as fastq.gz
      tumor_R1: tumor_R1.fastq.gz
      tumor_R2: tumor_R2.fastq.gz
      entity: BRCA
  protocol: tumorOnly
```

Additionally, a non-matching normal BAM file is required for sequenza to work. If you don't analyse all the chromosomes you have to adjust the `chromosomes` entry accordingly.

```yaml
[..]
sequenza:
  # define sequenza-utils parameter
  # --window WINDOW; Window size used for binning the original seqz file. Default is 50.
  window: 50
  # if used for samples without mathcing normal as control a separate non-matching-normal file in bam format is needed;
  # file should be stored in references/sequenza
  nonMatchingNormal: non_matching_normal.bam
  chromosomes: chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX
```

### Setting up the environment

The `costum.yaml` is intended to add parameters specifying the local environment. This could encompass the resources available, i.e. number of cores and memory, the processing author as well as the reference genome and / or capture region files.
Of course, all the settings could be set in the `patient.yaml`as well.

```yaml
common:
  author: MIRACUM-Pipe
  center: Freiburg
  memory: 150g
  cpucores: 12
  
reference:
  genome: hg19.fa
  length: hg19_chr.len
  dbSNP: snp150hg19.vcf.gz
  mappability: out100m2_hg19.gem
  sequencing:
    # target region covered by the sequencer in .bed format
    captureRegions: V5UTR.bed
    # file containing all the covered genes as HUGO Symbols
    captureGenes: V5UTR_Targets.txt
    # target region in Mega bases covered
    coveredRegion: 75
    # target / capture region kit name
    captureRegionName: V5UTR
    # target capture correlation factors for mutation signature analysis
    captureCorFactors : targetCapture_cor_factors.rda
```

### Run the pipeline

There are multiple possibilities to run the pipeline:

#### Whole-exome sequencing

Assumption: Patient folder name *Patient_example* within the *input* folder under assets/input.

- run complete pipeline on one patient
  
  ```bash
  ./miracum_pipe.sh -p wes -d Patient_example
  ```

- run a specific task on a given patient; possible tasks *td* (tumor sample alignment), *gd* (germline sample alignment), *td_gd_parallel* (td and gd in parallel), *vc* (variant calling), *cnv* (copy number calling), *vc_cnv_parallel* (vc and cnv parallel), *report* (report generation)
  
  ```bash
  ./miracum_pipe.sh -p wes -d Patient_example -t task
  ```

- run all unprocessed (no .processed file in the dir) patients
  
  ```bash
  ./miracum_pipe.sh -p wes
  ```

For more information see at the help of the command by running:

```bash
./miracum_pipe.sh
```

#### tNGS

Assumption: Patient folder name *TSO500_example* within the *input* folder under assets/input.

- run complete pipeline on one patient
  
  ```bash
  ./miracum_pipe.sh -p panel -d TSO500_example
  ```

- run a specific task on a given patient; possible tasks *td* (tumor sample alignment), *vc* (variant calling), *cnv* (copy number calling), *vc_cnv_parallel* (vc and cnv in parallel) *report* (report generation)
  
  ```bash
  ./miracum_pipe.sh -p panel -d TSO500_example -t task
  ```

- run all unprocessed (no .processed file in the dir) patients
  
  ```bash
  ./miracum_pipe.sh -p panel
  ```

For more information see at the help of the command by running:

```bash
./miracum_pipe.sh
```

#### tumorOnly

Assumption: Patient folder name *Patient_example* within the *input* folder under assets/input.

- run complete pipeline on one patient
  
  ```bash
  ./miracum_pipe.sh -p tumorOnly -d Patient_example
  ```

- run a specific task on a given patient; possible tasks *td* (tumor sample alignment), *vc* (variant calling), *cnv* (copy number calling), *vc_cnv_parallel* (vc and cnv in parallel) *report* (report generation)
  
  ```bash
  ./miracum_pipe.sh -p tumorOnly -d Patient_example -t task
  ```

- run all unprocessed (no .processed file in the dir) patients
  
  ```bash
  ./miracum_pipe.sh -p tumorOnly
  ```

For more information see at the help of the command by running:

```bash
./miracum_pipe.sh
```

### Parallel computation

The MIRACUM-Pipe consits of five major steps (tasks) of which several can be computed in parallel:

- `td` and `gd`
- `vc` and `cnv`
- `report` which is the last task and bases onto the results of the 4 prior tasks

After the pipeline finishes successfully, it creates the file `.processed` into the patient's direcotry. Per default processed patients are skipped.
The flag `-f` forces a recomputation and neglects that file. Furhtermore, sometimes it is required to rerun a single task. Therefore, use the flag `-t`.

## Logging

MIRACUM-pipe writes its logfiles into `output/<patient_name>/log`. For each task in the pipeline an own logfile is created. With the help of these logfiles one can monitor the current status of the pipeline process.

## Parallell & sequential computing

In `conf/custom.yaml` one can setup ressource parameters as cpucores and memory. If not intentionally called the pipeline on as single thread (sequentially), several tasks compute in parallel. The ressources are divided, thus you can enter the real 100% ressource you want to offer the entire pipline processes. Single threaded is intended to be used in case of limited hardware ressources or very large input files.

**BEWARE**: if you set tmp to be a tempfs (into ram), please consider this, while deciding the process ressources.

## Run the docker image behind a proxy

If you need a proxy to connect to the internet you need to change the command running the docker. We provided the needed parameters in the docker run command. You only need to uncomment the lines 86-93 in [miracum_pipe.sh](https://github.com/AG-Boerries/MIRACUM-Pipe-docker/blob/master/miracum_pipe.sh), add the proxy server address and port and comment or delete the lines 76-83.

## Used annotation databases

The following annotation databases are used during runtime of MIRACUM-Pipe. The default set could be easily extended.

- refGene
- dbNSFP v4.1a
- gnomAD v2.1.1 (Genome)
- dbSNP
- ClinVar
- InterVar
- COSMIC v91
- OncoKB
  - Actionalbe Genes
  - Cancer Genes
- FANNSDB (Condel)
- TARGET DB

## Limitations

MIRACUM-Pipe is currently test for the whole-exome protocol for the capture kits V5UTR and V6. The tool used for mutation signature analysis is currently only compatible with the following kits:

- Agilent4withUTRs
- Agilent4withoutUTRs
- Agilent5withUTRs
- Agilent5withoutUTRs
- SomSig
- hs37d5
- IlluminaNexteraExome
- Agilent6withoutUTRs
- Agilent6withUTRs
- Agilent7withoutUTRs

The name of the kit has to be supplied with the *captureRegionName* parameter. We introduced abbreviations for Agilent6withoutUTRs (V6), Agilent6withUTRs (V6UTR) and Agilent5withUTRs (V5UTR) which could be used.

For the tNGS protocol MIRACUM-Pipe is tested for the Illumina TruSight Tumor 170 panel.

## License

This work is licensed under [GNU Affero General Public License version 3](https://opensource.org/licenses/AGPL-3.0).
