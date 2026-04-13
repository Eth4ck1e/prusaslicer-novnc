#!/bin/bash
set -e

TMPDIR="$(mktemp -d)"
GITHUB_TOKEN="${2:-}"

if [ -n "$GITHUB_TOKEN" ]; then
  curl -SsL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest > $TMPDIR/latest.json
else
  curl -SsL \
    https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest > $TMPDIR/latest.json
fi

# Validate we got a real response, not a rate-limit or error message
if jq -e '.message' $TMPDIR/latest.json > /dev/null 2>&1; then
  echo "ERROR: GitHub API returned an error:" >&2
  jq -r '.message' $TMPDIR/latest.json >&2
  exit 1
fi

# Try older-distros GTK3 first (broader compatibility), fall back to standard GTK3
url=$(jq -r '[.assets[] | select(.browser_download_url | test("linux-x64-older-distros-GTK3.*\\.AppImage$"))] | .[0].browser_download_url' $TMPDIR/latest.json)
name=$(jq -r '[.assets[] | select(.browser_download_url | test("linux-x64-older-distros-GTK3.*\\.AppImage$"))] | .[0].name' $TMPDIR/latest.json)

if [ -z "$url" ] || [ "$url" = "null" ]; then
  url=$(jq -r '[.assets[] | select(.browser_download_url | test("linux-x64-GTK3.*\\.AppImage$"))] | .[0].browser_download_url' $TMPDIR/latest.json)
  name=$(jq -r '[.assets[] | select(.browser_download_url | test("linux-x64-GTK3.*\\.AppImage$"))] | .[0].name' $TMPDIR/latest.json)
fi

if [ -z "$url" ] || [ "$url" = "null" ]; then
  echo "ERROR: Could not find a PrusaSlicer AppImage in the latest release assets:" >&2
  jq -r '.assets[].name' $TMPDIR/latest.json >&2
  exit 1
fi

version=$(jq -r .tag_name $TMPDIR/latest.json)

request=$1

case $request in
  url)     echo "$url" ;;
  name)    echo "$name" ;;
  version) echo "$version" ;;
  *)       echo "Unknown request: $request" >&2; exit 1 ;;
esac

exit 0
