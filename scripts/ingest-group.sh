#!/bin/bash

set -ex

START="${1}"
STEP="${2}"
STEPS="${3}"

for i in $(seq 0 ${STEPS}); do
    ./scripts/ingest-repos.sh $((START + i * STEP)) $((STEP)) &> logs/ingest-$i.txt &
done

wait

docker system prune -af

make build-dockerception
