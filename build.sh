#!/usr/bin/env bash

WORKDIR=$(mktemp -dp .)

# Parameter given?
if [ -z "$1" ]; then
    echo "Error. Please provide name of minimal container to build."
    echo "Syntax: $0 <name>"
    exit 1
fi

CONTAINER="$1"

if [ ! -d "${CONTAINER}" ]; then
    echo "The directory $CONTAINER does not exist."
    exit 2
fi

cat Dockerfile.template - <<< "ENTRYPOINT [\"$(cat ${CONTAINER}/ENTRYPOINT_BIN)\"]" > ${WORKDIR}/Dockerfile
cp collect.sh ${WORKDIR}
cp ${CONTAINER}/* ${WORKDIR}

docker build --no-cache \
  --build-arg EXTRA_PACKAGES="$(cat ${CONTAINER}/EXTRA_PACKAGES)" \
  --build-arg BINARIES="$(cat ${CONTAINER}/BINARIES)" \
  -t minimal-${CONTAINER} ${WORKDIR}

sleep 1

docker tag minimal-${CONTAINER}:latest minimal-${CONTAINER}:$(./${WORKDIR}/get_version.sh)

# Cleanup
rm -rf ${WORKDIR}/
