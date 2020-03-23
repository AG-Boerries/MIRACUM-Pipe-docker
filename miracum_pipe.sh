#!/usr/bin/env bash

readonly DIR_MIRACUM="/opt/MIRACUM-Pipe"

function join_by { local IFS="$1"; shift; echo "$*"; }

function usage() {
  docker run -it --name run-miracum-pipeline --rm $1:$2 "${DIR_MIRACUM}"/miracum_pipe.sh -h
  echo ""
  echo "additional optional flags:"
  echo "  -r                    set temporary folder into RAM"
  echo "  -n                    docker repo name (default is agboerries/miracum_pipe)"
  echo "  -v version            specify version (default is \"latest\")"
  exit 1
}

PARAM_DOCKER_REPO_NAME="agboerries/miracum_pipe"

while getopts t:p:d:v:n:fsrh option; do
  case "${option}" in
  t) readonly PARAM_TASK=$OPTARG;;
  p) readonly PARAM_PROTOCOL=$OPTARGS;;
  f) readonly PARAM_FORCED=true;;
  d) readonly PARAM_DIR_PATIENT=$OPTARG;;
  v) PIPELINE_VERSION=$OPTARG;;
  r) readonly PARAM_RAM=$OPTARG;;
  s) readonly PARAM_SEQ=true;;
  n) PARAM_DOCKER_REPO_NAME=$OPTARG;;
  h) readonly SHOW_USAGE=true;;
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

[[ -z "${PIPELINE_VERSION}" ]] && PIPELINE_VERSION='latest'
[[ "${SHOW_USAGE}" ]] && usage "${PARAM_DOCKER_REPO_NAME}" "${PIPELINE_VERSION}"

# conf as volume
if [[ -d $(pwd)/conf ]]; then
  readonly VOLUME_CONF="-v $(pwd)/conf/custom.yaml:${DIR_MIRACUM}/conf/custom.yaml"
fi

# call script
if [[ "${PARAM_FORCED}" ]]; then
  opt_args='-f'
fi

if [[ "${PARAM_TASK}" ]]; then
  opt_args="${opt_args} -t ${PARAM_TASK}"
fi

if [[ "${PARAM_PROTOCOL}" ]]; then
  opt_args="${opt_args} -p ${PARAM_TASK}"
fi

if [[ "${PARAM_SEQ}" ]]; then
  opt_args="${opt_args} -s"
fi

if [[ "${PARAM_DIR_PATIENT}" ]]; then
  opt_args="${opt_args} -d ${PARAM_DIR_PATIENT}"
fi

# tmp in ram
if [[ "${PARAM_RAM}" ]]; then
  readonly TMP_RAM="--tmpfs /tmp:exec"
fi

echo "running \"${DIR_MIRACUM}/miracum_pipe.sh ${opt_args}\" of docker miracumpipe:${PIPELINE_VERSION}"
echo "---"
docker run -it --name run-miracum-pipeline --rm ${TMP_RAM} ${VOLUME_CONF} \
  -u $(id -u $USER) \
  -v "$(pwd)/assets/input:${DIR_MIRACUM}/assets/input" \
  -v "$(pwd)/assets/output:${DIR_MIRACUM}/assets/output" \
  -v "$(pwd)/assets/references:${DIR_MIRACUM}/assets/references" \
  -v "$(pwd)/tools/annovar:${DIR_MIRACUM}/tools/annovar" \
  -v "$(pwd)/tools/gatk:${DIR_MIRACUM}/tools/gatk" \
  -v "$(pwd)/databases:${DIR_MIRACUM}/databases" ${PARAM_DOCKER_REPO_NAME}:"${PIPELINE_VERSION}" "${DIR_MIRACUM}/miracum_pipe.sh" ${opt_args}

# for running behind a proxy use this commad and fill in your proxy
#docker run -it --env http_proxy="http://proxy.server.de:port" --env https_proxy="http://proxy.server.de:port" --name run-miracum-pipeline --rm ${TMP_RAM} ${VOLUME_CONF} \
#  -u $(id -u $USER) \
#  -v "$(pwd)/assets/input:${DIR_MIRACUM}/assets/input" \
#  -v "$(pwd)/assets/output:${DIR_MIRACUM}/assets/output" \
#  -v "$(pwd)/assets/references:${DIR_MIRACUM}/assets/references" \
#  -v "$(pwd)/tools/annovar:${DIR_MIRACUM}/tools/annovar" \
#  -v "$(pwd)/tools/gatk:${DIR_MIRACUM}/tools/gatk" \
#  -v "$(pwd)/databases:${DIR_MIRACUM}/databases" ${PARAM_DOCKER_REPO_NAME}:"${PIPELINE_VERSION}" "${DIR_MIRACUM}/miracum_pipe.sh" ${opt_args}