#!/bin/bash
# Regenerates the version table in README.md (between the <!-- versions:start --> and
# <!-- versions:end --> markers) from the labels of the published images.
# The table is built from the mediawiki-ci image, which carries all labels.
#
# The combinations are the entries of gesinn-it/docker-mediawiki-base's matrix.json that
# trigger a build in this repository ("downstream": true).
#
# Environment:
#   IMAGE_REPOSITORY   published image, default gesinn/mediawiki-ci
#   MATRIX_URL         matrix.json of docker-mediawiki-base
set -euo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ./helpers.sh

repository="${IMAGE_REPOSITORY:-gesinn/mediawiki-ci}"
matrix_url="${MATRIX_URL:-https://raw.githubusercontent.com/gesinn-it/docker-mediawiki-base/main/matrix.json}"
readme="README.md"
start='<!-- versions:start -->'
end='<!-- versions:end -->'

grep -qxF "$start" "$readme" && grep -qxF "$end" "$readme" \
	|| { echo "Error: markers ${start} / ${end} not found in ${readme}" >&2; exit 1; }

matrix="$(curl -fsSL "$matrix_url")" || { echo "Error: cannot fetch ${matrix_url}" >&2; exit 1; }

table="| MediaWiki | PHP | Composer | Node.js | npm | Grunt | MariaDB client | Xdebug | docker-mediawiki-tools |"$'\n'"|---|---|---|---|---|---|---|---|---|"
while read -r entry; do
	mw="$(jq -r .mediawiki_version <<< "$entry")"
	php="$(jq -r .php_version <<< "$entry")"
	php_default="$(jq -r .php_default <<< "$entry")"

	IFS=':' read -r ref_type ref_value ref_sha <<< "$(mediawiki_ref "$mw")"
	if [[ "$ref_type" == "tag" ]]; then
		full_version="$ref_value"
	else
		full_version="${mw}-dev-${ref_sha:0:7}"
	fi

	image="${repository}:${full_version}-php${php}"
	# an entry that has not been built yet (e.g. a new pre-release) is skipped, any other error is fatal
	if ! annotations="$(docker buildx imagetools inspect "$image" --format '{{json .Manifest.Annotations}}' 2>&1)"; then
		if [[ "$annotations" == *"not found"* ]]; then
			echo "Warning: ${image} does not exist yet, skipped" >&2
			continue
		fi
		echo "Error: cannot inspect ${image}: ${annotations}" >&2
		exit 1
	fi

	# labels that an older image does not carry yet are shown as n/a
	label() { jq -r --arg k "$1" '.[$k] // "n/a"' <<< "$annotations"; }
	php_full="$(label it.gesinn.php.version)"
	[[ "$php" == "$php_default" ]] && php_full+=" (default)"
	[[ "$ref_type" == "tag" ]] || full_version+=" (pre-release)"

	table+=$'\n'"| ${full_version} | ${php_full} | $(label it.gesinn.composer.version) | $(label it.gesinn.nodejs.version) | $(label it.gesinn.npm.version) | $(label it.gesinn.grunt.version) | $(label it.gesinn.mariadb-client.version) | $(label it.gesinn.xdebug.version) | $(label it.gesinn.tools.version) |"
done < <(jq -c '.[] | select(.downstream == true)' <<< "$matrix")

tmp="$(mktemp)"
awk -v start="$start" -v end="$end" -v table="$table" '
	$0 == start { print; print table; skip = 1; next }
	$0 == end   { skip = 0 }
	!skip       { print }
' "$readme" > "$tmp"
cat "$tmp" > "$readme"
rm "$tmp"
