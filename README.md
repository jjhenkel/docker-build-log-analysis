# Shipwright

This repository contains the tools for building, clustering, analyzing, and fixing broken Dockerfiles. 

## Setup / Environment

There are a few prerequisite tools Shipwright relies on:

- A recent version of `make`
- A recent version of `Docker`
- `git` and other simple utilities

## Building

One of the key usages of Shipwright involves running _in-context Dockerfile builds_. To facilitate this, Shipwright provides the following `make` target: `TARGET="${SHA}" make run-dockerception`. This command will build the Dockerfile in the target git repository (identified by the commit SHA---see `./data/repo-metadata/just-commit-shas.txt` for a listing of repositories in our dataset). As part of this process, Shipwright will spin up a "Docker-inside-of-Docker" container to both: (i) clone the repository matching the given `${SHA}`, and (ii) attempt an _in-context_ build (with a 30 minute timeout). Results are saved to the `./data/build-results/<repo-id>/<commit-sha>/...` directory.

## Clustering & Analyzing

We provide the following example notebook for these tasks: [link to Google Collaboratory notebook](https://colab.research.google.com/drive/1NxLMvrx8XKsIwRrbcqVgAqCm__R5NF1n?usp=sharing).

## Fixing

Coming soon (secondary repository with further tools/scripts --- currently undergoing cleanup).




