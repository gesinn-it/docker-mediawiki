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

  # Stage 2: fallback to the maintenance branch when no tag exists yet.
  local branch="REL$(echo "$major_version" | tr '.' '_')"
  local sha
  sha=$(git ls-remote --heads https://github.com/wikimedia/mediawiki.git "$branch" |
    cut -f1)

  if [[ -n "$sha" ]]; then
    echo "branch:${branch}:${sha}"
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
