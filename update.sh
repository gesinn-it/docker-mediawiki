#!/bin/bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

mediawikiReleases=( "$@" )
if [ ${#mediawikiReleases[@]} -eq 0 ]; then
	mediawikiReleases=( 1.*/ )
fi
mediawikiReleases=( "${mediawikiReleases[@]%/}" )

echo ${mediawikiReleases[*]}

declare -A composerVersion=(
	[1.31]='1.10.24'
	[default]='2.1.14'
)

function mediawiki_version() {
	git ls-remote --sort=version:refname --tags https://github.com/wikimedia/mediawiki.git \
		| cut -d/ -f3 \
		| tr -d '^{}' \
		| grep -E "^$1" \
		| tail -1
}

for mediawikiRelease in "${mediawikiReleases[@]}"; do
	mediawikiReleaseDir="$mediawikiRelease"
	mediawikiVersion="$(mediawiki_version $mediawikiRelease)"
	composerVersion=${composerVersion[$mediawikiRelease]-${composerVersion[default]}}

	mkdir -p "$mediawikiReleaseDir"

	sed -r \
		-e 's!%%MEDIAWIKI_VERSION%%!'"$mediawikiVersion"'!g' \
		-e 's!%%MEDIAWIKI_MAJOR_VERSION%%!'"$mediawikiRelease"'!g' \
		-e 's!%%COMPOSER_VERSION%%!'"$composerVersion"'!g' \
		"Dockerfile.template" > "$mediawikiReleaseDir/Dockerfile"
done
