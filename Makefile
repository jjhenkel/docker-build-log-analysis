export SHELL:=/bin/bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)errexit

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

.PHONY: check-test-target
check-test-target:
ifndef TEST_TARGET
	$(error TEST_TARGET is a required parameter. (Usage: TEST_TARGET=random/<sha commit hash>.))
endif

.PHONY: test-dockerception
test-dockerception: | check-test-target build-dockerception ## Tests dockerception on a repository (user-supplied or random).
	@IMAGE_NAME="$(shell whoami)/dbla--dockerception:$(shell git rev-parse HEAD)"

	@if [ "${TEST_TARGET}" = "random" ] || [ "${TEST_TARGET}" = "r" ]; then
		INPUT_LINE="$$(                                             \
			cat "${ROOT_DIR}/data/repo-metadata/goldilocks-repos.csv" \
			| tail -n +2                                              \
			| shuf -n1                                                \
		)"
	else
		INPUT_LINE="$$(                                             \
			cat "${ROOT_DIR}/data/repo-metadata/goldilocks-repos.csv" \
			| tail -n +2                                              \
			| grep "$${TEST_TARGET}"                                  \
			| head -n1                                                \
		)"
	fi

	@docker run \
	  -it --rm \
		-e USER_ID="$(shell id -u)" \
		-e GROUP_ID="$(shell id -g)" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v "${ROOT_DIR}/data/build-results":/mnt/outputs \
		"$${IMAGE_NAME}" \
			"$${INPUT_LINE}"
