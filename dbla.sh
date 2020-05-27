#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd "${DIR}" &> /dev/null

make build-driver
IMAGE_NAME="$(whoami)/dbla--driver:$(git rev-parse HEAD)"

if [ "${1}" = "interactive" ] || [ "${1}" = "i" ]; then
  shift
  docker run --rm -it -v "${DIR}:/mnt" -w "/mnt" --entrypoint "bash" "${IMAGE_NAME}"
else
  echo "Sub-command '${1}' unrecognized."
  popd &> /dev/null
  exit 1
fi

popd &> /dev/null
exit 0
