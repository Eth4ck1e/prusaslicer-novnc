#!/bin/bash

TMPDIR="$(mktemp -d)"
GITHUB_TOKEN="${2:-}"

if [ -n "$GITHUB_TOKEN" ]; then
  AUTH_HEADER="-H \"Authorization: Bearer ${GITHUB_TOKEN}\""
else
  AUTH_HEADER=""
fi

curl -SsL ${AUTH_HEADER:+$AUTH_HEADER} https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest > $TMPDIR/latest.json

# Try the older-distros GTK3 AppImage first (broader compatibility), fall back to standard GTK3 AppImage
url=$(jq -r '.assets[] | select(.browser_download_url|test("linux-x64-older-distros-GTK3.*\\.AppImage$"))|.browser_download_url' $TMPDIR/latest.json | head -1)
name=$(jq -r '.assets[] | select(.browser_download_url|test("linux-x64-older-distros-GTK3.*\\.AppImage$"))|.name' $TMPDIR/latest.json | head -1)

if [ -z "$url" ]; then
  url=$(jq -r '.assets[] | select(.browser_download_url|test("linux-x64-GTK3.*\\.AppImage$"))|.browser_download_url' $TMPDIR/latest.json | head -1)
  name=$(jq -r '.assets[] | select(.browser_download_url|test("linux-x64-GTK3.*\\.AppImage$"))|.name' $TMPDIR/latest.json | head -1)
fi

version=$(jq -r .tag_name $TMPDIR/latest.json)

if [ -z "$url" ] || [ "$url" = "null" ]; then
  echo "ERROR: Could not find PrusaSlicer AppImage download URL. API response:" >&2
  cat $TMPDIR/latest.json >&2
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Wrong number of params"
  exit 1
fi

request=$1

case $request in

  url)
    echo $url
    ;;

  name)
    echo $name
    ;;

  version)
    echo $version
    ;;

  *)
    echo "Unknown request"
    ;;
esac

exit 0
