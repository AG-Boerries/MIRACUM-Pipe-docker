# MIRACUM-Pipe-docker
This repo offers a framework to easily work with the dockerized version of [MIRACUM-Pipe](https://github.com/AG-Boerries/MIRACUM-Pipe)

## Setup and installation
In order to run the miracum pipeline, one needs to setup tools and databases which we are not allowed to ship due to license issues.
We prepared this project in a way which allows you to easily add the specific components into the pipeline. Although most components can be installed by the shipped `setup.sh` script, some need manual interaction:

- tools
  - [annovar](http://download.openbioinformatics.org/annovar_download_form.php)

- databases
  - [hallmarks of cancer](http://bbglab.irbbarcelona.org)
    - fannsdb.tsv.gz
    - fannsdb.tsv.gz.tbi
  - [condel score](http://software.broadinstitute.org/gsea/msigdb/)
    - h.all.v7.0.entrez.gmt

For the tool annovar you need the downloadlink. Follow the link and request it by filling out the form. While `setup.sh` is running you'll be asked to enter this download link. Alternatively you could also install annovar by manually extracting it into the folder `tools`.
To install the databases install follow the link, register and download the listed files. Just place them into the folder `databaeses` of your cloned project.


## How to configure and run it
The project structure is as follows:
```
.
├── conf
│   └── custom.yaml
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
- the docker file ships with [default.yaml]() which is setup with default config parameters
- `conf/custom.yaml` contains settings for the entire runtime environment and overwrites `default.yaml`'s values
- In each patient directory one a `patient.yaml` can be created in which every setting of the other two configs can be overwritten.
  
  
### Setting up a patient
It is intended to create a patient folder in `input` for each patient containing `patient.yaml`. Further, we recommend to define in it at least the following parameters:
```yaml
sex: XX # or XY
annotation:
  germline: true # default is false
```
Place the germline R1 and R2 files as well as the tumor files (R1 and R2) into the folder. Either name them `germline_R{1/2}.fastqz.gz` and `tumor_R1.fastq.gz` or adjust your `patient.yaml` accordingly:
```yaml
[..]
common:
  files:
    tumor: tumor_R
    germline: germline_R
```

## License
This work is licensed under [GNU Affero General Public License version 3](https://opensource.org/licenses/AGPL-3.0).