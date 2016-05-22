#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

url='git://github.com/idno/Known-Docker'

commit="$(git log -1 --format='format:%H' -- Dockerfile $(awk 'toupper($1) == "COPY" { for (i = 2; i < NF; i++) { print $i } }' Dockerfile))"
fullVersion="$(grep -m1 'ENV KNOWN_VERSION ' ./Dockerfile | cut -d' ' -f3)"

echo '# maintainer: hello@withknown.com'
echo
echo "$fullVersion: ${url}@${commit}"
echo "${fullVersion%.*}: ${url}@${commit}"
echo "${fullVersion%.*.*}: ${url}@${commit}"
echo "latest: ${url}@${commit}"
