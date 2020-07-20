#!/bin/bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker pull jjhenkel/binnacle &> /dev/null

TARGET="${1}"
shift

cat "${TARGET}" | docker run -i --rm \
  jjhenkel/binnacle \
  analyze-stdin $@
