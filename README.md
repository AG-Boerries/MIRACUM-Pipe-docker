# MIRACUM-Pipe-docker

This repo offers a framework to easily work with the dockerized version of [MIRACUM-Pipe](https://github.com/AG-Boerries/MIRACUM-Pipe)

## Setup and installation

In order to run the miracum pipeline, one needs to setup tools and databases which we are not allowed to ship due to license issues.
We prepared this project in a way which allows you to easily add the specific components into the pipeline.
Prior running the setup script, some components need to be installed manually interaction:

- tools
  - [annovar](http://download.openbioinformatics.org/annovar_download_form.php)

- databases
  - [hallmarks of cancer](http://software.broadinstitute.org/gsea/msigdb/)
    - h.all.v7.0.entrez.gmt
  - [condel score](https://bbglab.irbbarcelona.org/fannsdb/)
    - fannsdb.tsv.gz
    - fannsdb.tsv.gz.tbi

For the tool annovar you need the download link. Follow the url above and request the link by filling out the form. They will send you an email.
While `setup.sh` is running you'll be asked to enter this download link. Alternatively you could also install annovar by manually extracting it into the folder `tools`.
To install the databases install follow the link, register and download the listed files. Just place them into the folder `databases` of your cloned project.

Next, run the setup script. We recommend to install everything, which dows **not** include the example and reference data. There are also options to install and setup parts:

```bash
./setup.sh -t all
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
    - Download the latest release for GRCh37 (as of October 2019 the latest release is v90):
      - VCF/CosmicCodingMuts.vcf.gz
      - VCF/CosmicNonCodingVariants.vcf.gz
      - CosmicMutantExport.tsv.gz
      - CosmicNCV.tsv.gz
    - unzip all archives
  - commands to build the annovar database
  
    ```bash
    prepare_annovar_user.pl -dbtype cosmic CosmicMutantExport.tsv -vcf CosmicCodingMuts.vcf > hg19_cosmic_coding.txt
    prepare_annovar_user.pl -dbtype cosmic CosmicNCV.tsv -vcf CosmicNonCodingVariants.vcf > hg19_cosmic_noncoding.txt
    ```

  - Move both created files to the annovar/humandb folder.

## How to configure and run it

The project structure is as follows:

```shell
.
├── conf
│   └── custom.yaml
│   └── default.yaml
├── databases
├── input
├── output
├── references
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
  germline: yes # default is no
```

Place the germline R1 and R2 files as well as the tumor files (R1 and R2) into the folder. Either name them `germline_R{1/2}.fastqz.gz` and `tumor_R{1/2}.fastq.gz` or adjust your `patient.yaml` accordingly:

```yaml
[..]
common:
  files:
    tumor: tumor_R
    germline: germline_R
```

### Run the pipeline

There are multiple possibilities to run the pipeline:

- run complete pipeline on one patient
  
  ```bash
  ./run-pipeline -d rel_patient_folder
  ```

- run a specific task on a given patient
  
  ```bash
  ./run-pipeline -d rel_patient_folder -t task
  ```

- run all unprocessed (no .processed file in the dir) patients
  
  ```bash
  ./run-pipeline
  ```

For more information see at the help of the command by running:

```bash
./run-pipeline -h
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

## License

This work is licensed under [GNU Affero General Public License version 3](https://opensource.org/licenses/AGPL-3.0).
