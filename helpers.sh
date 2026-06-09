#!/bin/bash

function mediawiki_ref() {
  local major_version="$1"

  # Stage 1: resolve latest stable tag for the requested major version.
  local tag
  tag=$(git ls-remote --sort=version:refname --tags https://github.com/wikimedia/mediawiki.git |
    cut -d/ -f3 |
    tr -d '^{}' |
    grep -E "^${major_version}\." |
    tail -1)

  if [[ -n "$tag" ]]; then
    echo "tag:${tag}"
    return 0
  fi

  # Stage 2: fallback to the latest dev image available on Docker Hub for this major version.
  # This ensures we use the exact hash that docker-mediawiki-base actually built,
  # rather than resolving the wikimedia/mediawiki branch HEAD independently (which may have moved on).
  local dev_sha
  dev_sha=$(curl -fsSL "https://hub.docker.com/v2/repositories/gesinn/mediawiki-base/tags?page_size=100" |
    python3 -c "
import sys, json, re, datetime
data = json.load(sys.stdin)
pattern = re.compile(r'^${major_version}-dev-([0-9a-f]{7})$')
matches = [(t['last_updated'], re.match(pattern, t['name']).group(1))
           for t in data.get('results', []) if re.match(pattern, t['name'])]
if matches:
    matches.sort(reverse=True)
    print(matches[0][1])
")

  if [[ -n "$dev_sha" ]]; then
    local branch="REL$(echo "$major_version" | tr '.' '_')"
    echo "branch:${branch}:${dev_sha}"
    return 0
  fi

  echo "Error: No tag or branch found for MediaWiki version ${major_version}" >&2
  return 1
}

function mediawiki_version() {
  local ref
  ref=$(mediawiki_ref "$1") || return 1

  IFS=':' read -r ref_type ref_value ref_sha <<< "$ref"
  if [[ "$ref_type" == "tag" ]]; then
    echo "$ref_value"
    return 0
  fi

  echo "${1}-dev-${ref_sha:0:7}"
}

function generate_tags () {
  local imageRepository=$1
  local mediawikiFullVersion=$2
  local mediawikiVersion=$3
  local phpVersion=$4
  local phpDefault=$5
  local refType=${6:-tag}

  local TAGS=""

  if [[ "${phpVersion}" == "${phpDefault}" ]]; then
    TAGS+="${imageRepository}:${mediawikiFullVersion},"
    if [[ "$refType" != "branch" ]]; then
      TAGS+="${imageRepository}:${mediawikiVersion},"
    fi
  fi

  TAGS+="${imageRepository}:${mediawikiFullVersion}-php${phpVersion}"
  if [[ "$refType" != "branch" ]]; then
    TAGS+=",${imageRepository}:${mediawikiVersion}-php${phpVersion}"
  fi

  echo "$TAGS"
}
