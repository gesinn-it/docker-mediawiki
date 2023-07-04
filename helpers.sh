#!/bin/bash

function mediawiki_version() {
  git ls-remote --sort=version:refname --tags https://github.com/wikimedia/mediawiki.git |
    cut -d/ -f3 |
    tr -d '^{}' |
    grep -E "^$1" |
    tail -1
}