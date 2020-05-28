export SHELL:=/bin/bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail:errexit

.ONESHELL:

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Cross-platform realpath from 
# https://stackoverflow.com/a/18443300
# NOTE: Adapted for Makefile use
define BASH_FUNC_realpath%%
() {
  OURPWD=$PWD
  cd "$(dirname "$1")"
  LINK=$(readlink "$(basename "$1")")
  while [ "$LINK" ]; do
    cd "$(dirname "$LINK")"
    LINK=$(readlink "$(basename "$1")")
  done
  REALPATH="$PWD/$(basename "$1")"
  cd "$OURPWD"
  echo "$REALPATH"
}
endef
export BASH_FUNC_realpath%%

.DEFAULT_GOAL := help

#######################################################################################################################
#######################################################################################################################

.PHONY: help
help: ## (MISC) This help.
	@grep -E \
		'^[\/\.0-9a-zA-Z_-]+:.*?## .*$$' \
		$(MAKEFILE_LIST) \
		| grep -v '<!PRIVATE>' \
		| sort -t'#' -k3,3 \
		| awk 'BEGIN {FS = ":.*?## "}; \
		       {printf "\033[36m%-34s\033[0m %s\n", $$1, $$2}'

#######################################################################################################################
#######################################################################################################################

.PHONY: build-driver
build-driver: ## Builds the `dbla` driver.
	@IMAGE_NAME="$(shell whoami)/dbla--driver:$(shell git rev-parse HEAD)"
	if [[ -z "${DBLA_DEBUG}" ]]; then
	  docker build -t "$${IMAGE_NAME}" "${ROOT_DIR}" &> /dev/null
	else
	  docker build -t "$${IMAGE_NAME}" "${ROOT_DIR}"
	fi

.PHONY: build-dockerception
build-dockerception: ## Builds the dockerception tool.
	@IMAGE_NAME="$(shell whoami)/dbla--dockerception:$(shell git rev-parse HEAD)"
	if [[ -z "${DBLA_DEBUG}" ]]; then
	  docker build -t "$${IMAGE_NAME}" "${ROOT_DIR}/tools/dockerception" &> /dev/null
	else
	  docker build -t "$${IMAGE_NAME}" "${ROOT_DIR}/tools/dockerception"
	fi

.PHONY: test-dockerception-random
test-dockerception-random: | build-dockerception ## Tests dockerception on a random repository.
	@IMAGE_NAME="$(shell whoami)/dbla--dockerception:$(shell git rev-parse HEAD)"
	@LINE=$(shell \
	  cat "${ROOT_DIR}/data/repo-metadata/goldilocks-repos.csv" \
		| shuf \
		| head -n1 \
	)
	@REPO_GIT_URL=$$(
		echo "$${LINE}" | awk -F',' '{ print $$14 }'
	)
	@REPO_COMMIT_SHA=$$(
		echo "$${LINE}" | awk -F',' '{ print $$24 }'
	)
	@REPO_ID=$$(
		echo "$${LINE}" | awk -F',' '{ print $$1 }'
	)
	docker run \
	  -it --rm \
		-e USER_ID=$(id -u) \
		-e GROUP_ID=$(id -g ) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v "${ROOT_DIR}/data/build-results":/mnt/outputs \
		"$${IMAGE_NAME}" \
			"$${REPO_GIT_URL}" "$${REPO_COMMIT_SHA}" "$${REPO_ID}"
