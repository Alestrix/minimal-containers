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

docker build --progress=plain --no-cache \
  --build-arg EXTRA_PACKAGES="$(cat ${CONTAINER}/EXTRA_PACKAGES)" \
  --build-arg BINARIES="$(cat ${CONTAINER}/BINARIES)" \
  -t alestrix/minimal-${CONTAINER} ${WORKDIR}

sleep 1

IMAGENAME="alestrix/minimal-${CONTAINER}:latest"
IMAGENAME_VER="alestrix/minimal-${CONTAINER}:$(./${WORKDIR}/get_version.sh)"

docker tag ${IMAGENAME} ${IMAGENAME_VER}
# docker push ${IMAGENAME}
# docker push ${IMAGENAME_VER}

# Cleanup
if [[ "$WORKDIR" == ./tmp* ]]; then
  rm -rf -- "$WORKDIR"/
else
  echo "Error: WORKDIR does not seem to be a proper temporary working directory."
  echo "       Refusing to delete, please clean up manually."
  exit 3
fi
