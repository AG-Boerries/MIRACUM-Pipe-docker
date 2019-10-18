# MIRACUM-Pipe-docker
This repo offers a framework to easily work with the dockerized version of [MIRACUM-Pipe](https://github.com/AG-Boerries/MIRACUM-Pipe)

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

## Setup and installation
In order to run the miracum pipeline, one needs to setup tools and databases which we are not allowed to ship due to license issues.
We prepared this project in a way which allows you to easily add the specific components into the pipeline. Although most components can be installed by the shipped `setup` script, some need manual interaction:

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

## License
This work is licensed under [GNU Affero General Public License version 3](https://opensource.org/licenses/AGPL-3.0).