#!/bin/bash

while read -r SHA
do
  TARGET="${SHA}" make run-dockerception
done < <(
  cat data/repo-metadata/just-commit-shas.txt | \
    tail -n+$((${1} + 2)) | \
    head -n${2} \
)
