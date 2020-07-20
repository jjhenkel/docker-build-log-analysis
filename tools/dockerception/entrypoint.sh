#!/bin/bash

TIME_START=$(date +%s)

function cleanup {
  echo "[DBLA]   + Fixing permissions..."
  chown -R "${USER_ID}:${GROUP_ID}" "/mnt/outputs/${REPO_ID}"

  TIME_END=$(date +%s)
  echo "[DBLA]   + Finished in $((TIME_END - TIME_START)) seconds."
}
trap cleanup EXIT SIGINT SIGTERM

echo "[DBLA] Ingesting repository..."

LABELS="repo_id","repo_name","full_name","owner_login","owner_id","description","is_fork","created_at","updated_at","pushed_at","meta_scraped_at","file_list_scraped_at","git_url","clone_url","html_url","repo_size","stargazers_count","watchers_count","repo_language","forks_count","archived","open_issues_count","default_branch","repo_commit","homepage","ingested_file_list","failed_to_ingest_file_list","extracted_devops_files","file_list_truncated"

MLR_ARGS="--csv --implicit-csv-header --headerless-csv-output"

REPO_ID=$(
  echo "${1}" | mlr ${MLR_ARGS} cut -f 1
)
REPO_URL=$(
  echo "${1}" | mlr ${MLR_ARGS} cut -f 14
)
REPO_COMMIT=$(
  echo "${1}" | mlr ${MLR_ARGS} cut -f 24
)

echo "[DBLA]   + Cloning '${REPO_URL}'..."

mkdir -p "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}"

echo "${REPO_COMMIT}" \
  &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/commit-sha.txt"

echo "${1}" | mlr ${MLR_ARGS} --ojson label "${LABELS}" \
  | jq '. + {"dbla_processed_at": ( now | strflocaltime("%Y-%m-%d %H:%M:%S") )}' \
  &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/meta.json"

git clone "${REPO_URL}" /target \
  &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/git-log.txt"

if [ ! -d /target ]; then
  echo "[DBLA]   - Error: /target does not exist. Clone failed?"
  exit 1
fi

cd /target

echo "[DBLA]   + Checkout @${REPO_COMMIT}..."

git checkout "${REPO_COMMIT}"  \
  >> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/git-log.txt" \
  2>&1

DOCKERFILE=$(
  find /target -type f -iname '*dockerfile*' \
  | head -n1
)
echo "[DBLA]   + Found '${DOCKERFILE}'..."

cat "${DOCKERFILE}" &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/Dockerfile"

# Just get lists of files/dirs (may be helpful, at least for debugging)
find /target -type f  &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/all-files.txt"
find /target -type d &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/all-directories.txt"

echo "[DBLA]   + Building docker image..."
timeout -s SIGKILL 1800 stdbuf -o0 -e0 docker build --rm -t "dbla-temporary:${REPO_ID}" -f "${DOCKERFILE}" /target \
  > "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/build-log-stdout.txt" \
  2> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/build-log-stderr.txt"
RESULT="$?"

if [ "${RESULT}" -eq 0 ]; then
  echo "[DBLA]      + Build Succeeded!"
  echo "Exit Code: $?" \
    > "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/result-succeeded.txt"
  docker history --no-trunc --format '{{json .}}' "dbla-temporary:${REPO_ID}" \
    | jq -s '.' &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/history.json"
  echo "[DBLA]      + Image history saved."
elif [ "${RESULT}" -eq 137 ]; then
  echo "Exit Code: $?" \
    > "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/result-timed-out.txt"
  echo "[DBLA]      - Build Timeout!"
else
  echo "Exit Code: $?" \
    > "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/result-build-failed.txt"
  echo "[DBLA]      - Build Failed!"
fi

echo "[DBLA]   + Cleanup..."
rm -f "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/image-deps.txt"
touch "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/image-deps.txt"
for IMAGE in $(docker images -q); do
  DEPS="$(/app/docker-find-dependants.sh "${IMAGE}")"
  if echo "${DEPS}" | grep -q "dbla-temporary:${REPO_ID}"; then
    echo "${DEPS}" | grep 'Image' | awk '{ print $2 }' >> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/image-deps.txt"
  fi 
done
docker rmi $(cat "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/image-deps.txt") \
  &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}/image-deps-cleanup-log.txt"

echo "[DBLA]   + Extracting file chunks..."
/app/chunk.sh "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}"
