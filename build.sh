#!/usr/bin/env bash

WORKDIR=$(mktemp -dp .)

# Parameter given?
if [ -z "$1" ]; then
    echo "Error: Please provide name of minimal container to build."
    echo "Syntax: $0 <name>"
    exit 1
fi

CONTAINER="$1"

if [ ! -d "${CONTAINER}" ]; then
    echo "Error: The directory $CONTAINER does not exist."
    exit 2
fi

cp ${CONTAINER}/* ${WORKDIR}
cp collect.sh ${WORKDIR}
cat Dockerfile.template ${WORKDIR}/ENTRYPOINT > ${WORKDIR}/Dockerfile

docker build --no-cache \
  --build-arg EXTRA_PACKAGES="$(cat ${CONTAINER}/EXTRA_PACKAGES)" \
  --build-arg BINARIES="$(cat ${CONTAINER}/BINARIES)" \
  -t minimal-${CONTAINER} ${WORKDIR}

sleep 1

docker tag minimal-${CONTAINER}:latest minimal-${CONTAINER}:$(./${WORKDIR}/get_version.sh)

# Cleanup
if [[ "$WORKDIR" == ./tmp* ]]; then
  rm -rf -- "$WORKDIR"/
else
  echo "Error: WORKDIR does not seem to be a proper temporary working directory."
  echo "       Refusing to delete, please clean up manually."
  exit 3
fi
