#!/bin/bash

function mediawiki_version() {
  git ls-remote --sort=version:refname --tags https://github.com/wikimedia/mediawiki.git |
    cut -d/ -f3 |
    tr -d '^{}' |
    grep -E "^$1" |
    tail -1
}
function generate_tags () {
	local imageRepository=$1
	local mediawikiFullVersion=$2
	local mediawikiVersion=$3
	local phpVersion=$4
	local phpDefault=$5

	if [[ ${phpVersion} == ${phpDefault}  ]]; then
			TAGS+="${imageRepository}:${mediawikiVersion},"
			TAGS+="${imageRepository}:${mediawikiFullVersion},"
	fi
	TAGS+="${imageRepository}:${mediawikiFullVersion}-php${phpVersion},"
	TAGS+="${imageRepository}:${mediawikiVersion}-php${phpVersion},"

	echo $TAGS
}