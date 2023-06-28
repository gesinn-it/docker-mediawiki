#!/bin/bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

source ./helpers.sh

if [ "$#" -ne 3 ]; then
  echo "not enough arguments provided"
  exit 1
fi

github_mw_version="$1"
github_php_version="$2"
github_db_type="$3"

mediawikiVersion="$(mediawiki_version $github_mw_version)"
composerVersion=${composerVersion[$github_mw_version]-${composerVersion[default]}}
sed -r \
	-e 's!%%MEDIAWIKI_VERSION%%!'"$mediawikiVersion"'!g' \
	-e 's!%%MEDIAWIKI_MAJOR_VERSION%%!'"$github_mw_version"'!g' \
	-e 's!%%COMPOSER_VERSION%%!'"$composerVersion"'!g' \
	"Dockerfile-${dbType}.template" >"./Dockerfile"

