#!/bin/bash

set -e

# This script will launch the build of the ProtoR in the
# docker container, and then run the tests in it.
# NOTE: the credentials are taken from host, to avoid keeping them
#   hardcoded in the image or harness scripting
#
# Synopsis:
#   docker_build.sh [--kernel_version=KERNEL_VERSION]
#                   [--docker-file=DOCKER_FILE_PATH]
#                   THE_DOCKER_CONTEXT_DIR
#

LIGHT_BLUE='\033[1;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function log()
{
    echo -e $@
}

function cleanup()
{
    echo -e "${NC}"
}

trap cleanup EXIT

#### Script arguments parsing

KVER=""
TARGET_CONTEXT="."
DOCKER_FILE=""
DOCKER_OUT_IMAGE_TAG=""

log "===== docker build params ====="
while (( "$#" > "0" )); do
    arg="$1"
    case ${arg} in
    --kernel-version=*)
        KVER=${arg#"--kernel-version="}
        log "  kernel version: ${GREEN}${KVER}${NC}"
        ;;
    --docker-file=*)
        DOCKER_FILE=${arg#"--docker-file="}
        log "  docker file: ${GREEN}${DOCKER_FILE}${NC}"
        ;;
    --docker-out-image-tag=*)
        DOCKER_OUT_IMAGE_TAG=${arg#"--docker-out-image-tag="}
        log "  out image tag: ${GREEN}${DOCKER_OUT_IMAGE_TAG}${NC}"
        ;;
    *)
        if (( "$#" > "1" )); then
            log "$0: ${RED}unknown arg:${NC} ${arg}\n${RED}Aborting.${NC}"
            log "${YELLOW}NOTE: the context argument must be the last one!${NC}"
            exit 1
        fi
        TARGET_CONTEXT="${arg}"
        log "  docker build context: ${GREEN}${TARGET_CONTEXT}${NC}"
        ;;
    esac
    shift
done
log "==== docker build params EOF =="

#### Extra build args parsing section

DOCKER_BUILD_ARGS=""
if [ ! -z "${KVER}" ]; then
    log "NOTE: the following externall defined kernel version will be used: " \
         "${LIGHT_BLUE}${KVER}${NC}"
    DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} --build-arg kernel_version=${KVER}"
else
    log "NOTE: the kernel version is not set, thus the" \
         " ${LIGHT_BLUE}docker default kernel${NC}" \
         " will be used. See the Dockerfile for the value."
fi

if [ ! -z "${DOCKER_FILE}" ]; then
    log "Custom docker file: ${DOCKER_FILE}"
    DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} --file ${DOCKER_FILE}"
fi

if [ ! -z "${DOCKER_OUT_IMAGE_TAG}" ]; then
    log "Output docker image tag is set to: ${DOCKER_OUT_IMAGE_TAG}"
    DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} --tag ${DOCKER_OUT_IMAGE_TAG}"
fi

echo "Resulting docker build arguments: '${DOCKER_BUILD_ARGS}'"

#### SSH keys exposing section

echo "First: adding the SSH keys to ssh-agent, to make docker"\
     " capable to pull from the ssh repos."

agents_count=$(ps -aux | grep ssh-agent | grep -v grep | wc -l)

if [ ${agents_count} == 0 ]; then
    echo "Launching the ssh-agent to make your native keys available"\
         " to the docker build."
    eval $(ssh-agent)
    sleep 2
else
    echo "SSH agent is already launched."
fi

echo "Additing ssh keys to the ssh-agent..."

for key in ${HOME}/.ssh/*; do
    if ! [ -f "${key}" ]; then continue; fi
    if [[ "${key}" =~ ^.*\.pub$ ]]; then continue; fi
    if [[ "${key}" =~ ^.*known_hosts$ ]]; then continue; fi
    if [[ "${key}" =~ ^.*authorized_keys$ ]]; then continue; fi
    if [[ "${key}" =~ ^.*config$ ]]; then continue; fi
    echo "Adding the key to ssh-agent: ${key}"
    ssh-add "${key}" || true
done

echo
echo "The list of available ssh keys:"
echo -e "===== Available keys =====${GREEN}"
ssh-add -l
echo -e "${NC}=== Available keys EOF ==="
echo

keys_count=$(ssh-add -l 2>/dev/null | wc -l)

if [ ${keys_count} == 0 ]; then
    echo "ERROR: you have no keys defined for your ssh-agent." \
         " This will make impossible to docker to pull from ssh-driven" \
         " protected repositories."
    exit 1
fi

echo '**********************************************'
echo -e "${YELLOW}NOTE: if build fails, please check first of all if you have " \
     "added all relevant ssh keys (use 'ssh-add PATH_TO_KEY' command to" \
     " add them).${NC}"
echo '**********************************************'
echo

docker build --secret id=known_hosts,src=${HOME}/.ssh/known_hosts \
             --ssh default=$SSH_AUTH_SOCK     \
             ${DOCKER_BUILD_ARGS}             \
             ${TARGET_CONTEXT}                \
    && echo -e "Overall build and testing result: ${GREEN}PASSED${NC}" \
    || echo -e "Overall build and testing result: ${RED}FAILED${NC}"
