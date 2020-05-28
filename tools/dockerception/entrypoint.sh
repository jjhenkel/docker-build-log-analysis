#!/bin/sh

if [[ -z "${DBLA_DEBUG}" ]]; then
  set -ex
fi

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

mkdir -p "/mnt/outputs/${REPO_ID}"

echo "${1}" | mlr ${MLR_ARGS} --ojson label "${LABELS}" \
  | jq '. + {"dbla_processed_at": ( now | strflocaltime("%Y-%m-%d %H:%M:%S") )}' \
  &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}.meta.json"

git clone "${REPO_URL}" /target \
  &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}.git-log.txt"

cd /target

git checkout "${REPO_COMMIT}"  \
  >> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}.git-log.txt" \
  2>&1

DOCKERFILE=$(
  find /target -type f -iname '*dockerfile*' \
  | head -n1
)

cat "${DOCKERFILE}" &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}.Dockerfile"

docker build --rm -t dbla-temporary -f "${DOCKERFILE}" /target \
  &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}.build-log.txt"

if [ $? -eq 0 ]; then
  echo "Exit Code: $?" \
    > "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}.succeeded.txt"
  docker history --no-trunc --format '{{json .}}' dbla-temporary \
    | jq -s '.' &> "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}.history.json"
else
  echo "Exit Code: $?" \
    > "/mnt/outputs/${REPO_ID}/${REPO_COMMIT}.failed.txt"
fi

docker rmi dbla-temporary || true &> /dev/null

chown -R "${USER_ID}:${GROUP_ID}" "/mnt/outputs/${REPO_ID}"

# /kaniko/executor --help 
# /kaniko/executor \
#  --no-push \
#  --cache=false \
#  --dockerfile "${DOCKERFILE}" \
#  --context /target \
#  --verbosity info \
#  --tarPath /built-image \
#  --whitelist-var-run

