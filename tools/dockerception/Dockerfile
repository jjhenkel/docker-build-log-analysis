FROM docker:dind

RUN apk add --no-cache coreutils git curl openssh

COPY . /app

ENTRYPOINT [ "/app/entrypoint.sh" ]
