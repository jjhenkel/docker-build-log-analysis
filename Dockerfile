FROM debian:stretch

COPY ./utils /utils

ENV PATH="${PATH}:/utils/mlr:/utils/jq"
