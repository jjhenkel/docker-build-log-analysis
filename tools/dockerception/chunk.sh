#!/bin/bash

OUTPUT_DIR="${1}"

MAX_FILES="50"
MAX_LINES="200"
MAX_CHARS="10000"

SIZE_LIMIT="-size -2048k"
CONSTRAINTS="-type f ${SIZE_LIMIT}"

get_chunks () {
  echo "[DBLA]      + Chunking '${1}' files..."
  
  set -o noglob

  mkdir -p "${OUTPUT_DIR}/chunks"
  rm -f "${OUTPUT_DIR}/chunks/${1}.txt"
  touch "${OUTPUT_DIR}/chunks/${1}.txt"

  while IFS= read -r -d $'\0' LINE; do
    TARGET="$(echo "${LINE}" | awk '{ print $2 }' | tr -d '[:space:]')"
    
    QUALIFYING_LINES=$(
      cat "${TARGET}" \
      | tr -cd '\11\12\15\40-\176' \
      | sed '/^\s*$/d' \
      | wc -l
    )

    if [[ "${QUALIFYING_LINES}" -le 0 ]]; then
      continue
    fi

    cat "${TARGET}" \
      | tr -cd '\11\12\15\40-\176' \
      | sed '/^\s*$/d' \
      | head -n "${MAX_LINES}" \
      | python3 /app/chartok.py "${MAX_CHARS}" \
    >> "${OUTPUT_DIR}/chunks/${1}.txt"
  done < <( \
    find /target ${CONSTRAINTS} \( ${2} \) \
      -printf "%d %p\n" -print0 \
    | sort -nz \
    | head -zn "${MAX_FILES}" 
  )

  MATCHED=$(wc -l ${OUTPUT_DIR}/chunks/${1}.txt | awk '{ print $1 }')
  echo "[DBLA]         - Found ${MATCHED}/${MAX_FILES} matches."
}

# Chunk up 20 different kinds of files and do a char-level 
# tokenization

get_chunks txt '-iname *.txt'
get_chunks json '-iname *.json'
get_chunks yaml '-iname *.yaml -o -iname *.yml'
get_chunks cpp '-iname *.cpp -o -iname *.hpp -o -iname *.cc -o -iname *.cxx -o -iname *.hxx'
get_chunks c '-iname *.h -o -iname *.c'
get_chunks go '-iname *.go'
get_chunks shell '-iname *.sh'
get_chunks python '-iname *.py'
get_chunks java '-iname *.java'
get_chunks csharp '-iname *.cs'
get_chunks javascript '-iname *.js'
get_chunks typescript '-iname *.ts'
get_chunks toml '-iname *.toml'
get_chunks markdown '-iname *.md'
get_chunks rlang '-iname *.r'
get_chunks ruby '-iname *.rb'
get_chunks php '-iname *.php'
get_chunks lua '-iname *.lua'
get_chunks haskell '-iname *.hs'
get_chunks xml '-iname *.xml'

# Keep certain key files 

echo "[DBLA]      + Finding files of interest..."
mkdir -p "${OUTPUT_DIR}/files-of-interest"

find /target -type f \( \
  -iname 'package*.json' \
  -o -iname 'requirements*.txt' \
  -o -iname '*.nuspec' \
  -o -iname 'gemfile' \
  -o -iname 'travis.yml' \
  -o -iname 'travis.yaml' \
  -o -iname 'pom.xml' \
  -o -iname 'jenkinsfile' \
  -o -iname 'cargo.toml' \
  -o -path '.github/*' \
\) \
  -exec cp --parents \{\} "${OUTPUT_DIR}/files-of-interest/" \;

MATCHED=$(
  find ${OUTPUT_DIR}/files-of-interest/ -type f \
  | wc -l \
  | awk '{ print $1 }'
)
echo "[DBLA]         - Found ${MATCHED} matches."
