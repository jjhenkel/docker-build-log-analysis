#!/bin/bash

while read f; do
 cp "$f" ./to-analyze/$(basename $(dirname $f)).Dockerfile
done <targets.txt
