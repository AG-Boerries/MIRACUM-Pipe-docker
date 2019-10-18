# MIRACUM-Pipe-docker
This repo offers a framework to easily work with the dockerized version of [MIRACUM-Pipe](https://github.com/AG-Boerries/MIRACUM-Pipe)

## Setup and Installation
In order to run the miracum pipeline, one needs to setup tools and databases which we are not allowed to ship due to license issues.
We prepared this project in a way which allows you to easily add the specific components into the pipeline. Although most components can be installed by the shipped `setup` script, some need manual interaction:

- tools
  - [annovar]()

- databases
  - [hallmarks of cancer](http://bbglab.irbbarcelona.org)
    - fannsdb.tsv.gz
    - fannsdb.tsv.gz.tbi
  - [condel score](http://software.broadinstitute.org/gsea/msigdb/)
    - h.all.v7.0.entrez.gmt

For the tool annovar you need the downloadlink. Follow the link and request it by filling out the form. While `setup` is running you'll be asked to enter this download link. Alternatively you could also install annovar by manually extracting it into the folder `tools`.
To install the databases install follow the link, register and download the listed files. Just place them into the folder `databaeses` of your cloned project.


## How to configure and run it



## License
This work is licensed under [GNU Affero General Public License version 3](https://opensource.org/licenses/AGPL-3.0).