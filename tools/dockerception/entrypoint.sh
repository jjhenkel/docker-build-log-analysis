#!/bin/sh

set -ex

git clone "${1}" /target

cd /target

git checkout "${2}" &> /dev/null

DOCKERFILE=$(
  find /target -type f -iname '*dockerfile*' \
  | head -n1
)

mkdir -p "/mnt/outputs/${3}"

cat "${DOCKERFILE}" &> "/mnt/outputs/${3}/${2}.Dockerfile"

docker build --rm -t dbla-temporary -f "${DOCKERFILE}" /target \
  &> "/mnt/outputs/${3}/${2}.log"

if [ $? -eq 0 ]; then
  touch "/mnt/outputs/${3}/${2}.succeeded"
  docker history --no-trunc dbla-temporary \
    &> "/mnt/outputs/${3}/${2}.history"
else
  touch "/mnt/outputs/${3}/${2}.failed"
fi

docker rmi dbla-temporary || true &> /dev/null

chown -R "${USER_ID}:${GROUP_ID}" "/mnt/outputs/${3}"

# /kaniko/executor --help 
# /kaniko/executor \
#  --no-push \
#  --cache=false \
#  --dockerfile "${DOCKERFILE}" \
#  --context /target \
#  --verbosity info \
#  --tarPath /built-image \
#  --whitelist-var-run

