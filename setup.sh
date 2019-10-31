#!/usr/bin/env bash

SCRIPT_PATH=$(
  cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
  pwd -P
)

readonly VALID_TASKS=("all db_install db_setup tools_install tools_setup ref example")

function join_by { local IFS="$1"; shift; echo "$*"; }

function usage() {
  echo "usage: setup -t task"
  echo "  -t  task            specify task: $(join_by ' ' ${VALID_TASKS})"
  echo "  -h                  show this help screen"
  exit 1
}

while getopts d:t:ph option; do
  case "${option}" in
  d) readonly PARAM_DIR_PATIENT=$OPTARG ;;
  t) PARAM_TASK=$OPTARG ;;
  h) usage ;;
  \?)
    echo "Unknown option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Missing option argument for -$OPTARG" >&2
    exit 1
    ;;
  *)
    echo "Unimplemented option: -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# if no patient is defined
if [[ -z "${PARAM_TASK}" ]]; then
  PARAM_TASK='all'
fi


if [[ ! " ${VALID_TASKS[@]} " =~ " ${PARAM_TASK} " ]]; then
  echo "unknown task: ${PARAM_TASK}"
  echo "use one of the following values: $(join_by ' ' ${VALID_TASKS})"
  exit 1
fi


readonly DIR_TOOLS="${SCRIPT_PATH}/tools"
readonly DIR_DATABASES="${SCRIPT_PATH}/databases"
readonly DIR_ASSETS="${SCRIPT_PATH}/assets"

readonly DIR_INPUT="${DIR_ASSETS}/input"
readonly DIR_REF="${DIR_ASSETS}/references"

readonly DIR_SEQUENCING="${DIR_REF}/sequencing"

# direct download of any file from gdrive
# https://stackoverflow.com/questions/25010369/wget-curl-large-file-from-google-drive/49444877#49444877
function curlgdrive() {
  local fileid="${1}"
  local filename="${2}"
  local cookiefile="cookie-${fileid}"

  # download file using cookie information
  curl -c "${SCRIPT_PATH}/${cookiefile}" -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
  curl -Lb "${SCRIPT_PATH}/${cookiefile}" "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o "${filename}"

  # remove cookie
  rm -f "${SCRIPT_PATH}/${cookiefile}"
}

# example
######################################################################################
function setup_example() {
  echo "setting up example data"
  
  curlgdrive "11dQZzlkwmfdMrXgw_lWKDrjxWcWi_seC" Capture_Regions.tar.gz
  curlgdrive "1O6OTmB1o_XS5DokGmuZHDujvyRKHQmeP" data.tar.gz

  tar -xzf Capture_Regions.tar.gz -C "${DIR_SEQUENCING}" && rm -f Capture_Regions.tar.gz
  tar -xzf Capture_Regions.tar.gz -C "${DIR_INPUT}" && rm -f data.tar.gz

  echo "done"
}


# REF
######################################################################################
function setup_references() {
  echo "setting up reference data"

  curlgdrive "1QZSkniYbI1cWWj8CA6-FS93ViiAn8z_G" chromosomes.tar.gz
  curlgdrive "1rSC-IuRYhdVvulo2yrSkHSBgVAo4iRt0" genome.tar.gz
  curlgdrive "1w8PL_J6k0X96W6IkXkjOOi_VnsDaaw8U" mappability.tar.gz

  tar -xzf chromosomes.tar.gz -C "${DIR_REF}/Chromosomes" && rm -f chromosomes.tar.gz
  tar -xzf genome.tar.gz -C "${DIR_REF}/Genome" && rm -f genome.tar.gz
  tar -xzf mappability.tar.gz -C "${DIR_REF}/mappability" && rm -f mappability.tar.gz

  echo "done"
}


# TOOLS
######################################################################################
version_GATK="3.8-1-0-gf15c1c3ef"

########
# GATK #
########
function install_tool_gatk() {
  echo "installing tool gatk"
  cd "${DIR_TOOLS}" || exit 1

  echo "fetching gatk"
  # download new version
  wget "https://software.broadinstitute.org/gatk/download/auth?package=GATK-archive&version=${version_GATK}" \
      -O gatk.tar.bz2

  # unpack
  tar xjf gatk.tar.bz2
  rm -f gatk.tar.bz2

  # rename folder and file (neglect version information)
  mv GenomeAnalysisTK*/* gatk/
  rm -rf GenomeAnalysisTK*

  echo "done"
}



###########
# annovar #
###########
function install_tool_annovar() {
  echo "installing tool annovar"

  cd "${DIR_TOOLS}" || exit 1

  echo "please visit http://download.openbioinformatics.org/annovar_download_form.php to get the download link for annovar via an email"
  echo "enter annovar download link:"
  read -r url_annovar

  echo "fetching annovar"
  wget "${url_annovar}" \
      -O annovar.tar.gz

  # unpack
  tar -xzf annovar.tar.gz
  rm -f annovar.tar.gz

  cd annovar

  echo "done"
}

function setup_tool_annovar() {
  echo "setup tool annovar"
  echo "download databases"

  cd "${DIR_TOOLS}/annovar" || exit 1

  # Download proposed databases directly from ANNOVAR
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar refGene humandb/
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar dbnsfp35a humandb/
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar gnomad_exome humandb/
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar exac03 humandb/
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar esp6500siv2_ea humandb/
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar 1000g2015aug humandb/
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar avsnp150 humandb/
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar clinvar_20180603 humandb/
  ./annotate_variation.pl -buildver hg19 -downdb -webfrom annovar intervar_20180118 humandb/

  echo "done"
}

# databases
######################################################################################
function install_databases() {
  echo "installing databases"

  cd "${DIR_DATABASES}" || exit 1

  # dbSNP
  wget ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/All_20170710.vcf.gz -O "dbSNP/snp150hg19.vcf.gz"
  wget ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/All_20170710.vcf.gz.tbi -O "dbSNP/snp150hg19.vcf.gz.tbi"

  # CancerGenes
  wget https://github.com/oncokb/oncokb-public/blob/master/data/v1.15/CancerGenesList.txt

  # Cancer Hotspots
  wget http://www.cancerhotspots.org/files/hotspots_v2.xls

  # DGIdb
  wget http://www.dgidb.org/data/interactions.tsv -O DGIdb_interactions.tsv

  # Actionable alterations
  wget https://oncokb.org/api/v1/utils/allActionableVariants.txt

  echo "done"
}

function setup_databases() {
  echo "setup databases"

  BIN_RSCRIPT=$(which Rscript)
  if [[ -z "${BIN_RSCRIPT}" ]]; then
    echo "Rscript needs to be available and in PATH in order to install the databases"
    exit 1
  fi

  ## R Code for processing
  ${BIN_RSCRIPT} --vanilla -<<EOF
library(GSA)
gmt <- GSA.read.gmt('h.all.v7.0.entrez.gmt')
genesets <- gmt$genesets
names <- data.frame(Names = gmt$geneset.names, Descriptions = gmt$geneset.descriptions)
names(genesets) <- names$Names
hallmark <- genesets
save(hallmarksOfCancer, file = "hallmarksOfCancer_GeneSets.Rdata")
EOF

  rm -f h.all.v7.0.entrez.gmt

  echo "done"
}

case "${PARAM_TASK}" in
  "tools_install") 
    install_tool_gatk
    install_tool_annovar
  ;;

  "db_install") 
    install_databases
  ;;

  "db_setup")
    setup_databases
  ;;

  "tools_setup")
    setup_tool_annovar
  ;;

  "ref")
    setup_references
  ;;

  "example")
    setup_example
  ;;

  *) 
    install_tool_gatk
    install_tool_annovar
    setup_tool_annovar

    install_databases
    setup_databases

    setup_references
    setup_example

  ;;
esac
