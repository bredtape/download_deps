#!/usr/bin/env bash
# Usage: ./fetch-go-deps.sh <dir-with-go.txt-files> [output.zip]
#   *.go.txt         one module path per line; latest version is fetched
#   *.go_install.txt one main package per line; "go install" is run per line,
#                    populating the cache and verifying the tool builds
# Produces a single bundle with the GOPROXY-layout tree (cache/download),
# ready for upload via "jf rt u".
set -euo pipefail
shopt -s nullglob

SRC_DIR="$(realpath -e "${1:?dir with *.go.txt files}")"
OUT_ZIP="$(realpath -m "${2:-./go-deps-bundle.zip}")"

workdir="$(mktemp -d)"
export GOPATH="$workdir/go"
export GOMODCACHE="$GOPATH/pkg/mod"
export GOBIN="$workdir/bin"

for depfile in "$SRC_DIR"/*.go.txt; do
    project="$(basename "$depfile" .go.txt)"
    projdir="$workdir/projects/$project"
    mkdir -p "$projdir"
    (
        cd "$projdir"
        go mod init "local/$project" >/dev/null
        while IFS= read -r dep || [[ -n "$dep" ]]; do
            dep="${dep%%[[:space:]]*}"
            [[ -z "$dep" || "$dep" == \#* ]] && continue
            go get "${dep%%@*}@latest"
        done < "$depfile"
    )
    echo "OK: $project"
done

for installfile in "$SRC_DIR"/*.go_install.txt; do
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        pkg="${pkg%%[[:space:]]*}"
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        go install "${pkg%%@*}@latest"
        echo "OK: install ${pkg%%@*}"
    done < "$installfile"
done

(cd "$GOMODCACHE/cache" && zip -qr "$OUT_ZIP" "download" -x "download/sumdb/*")
chmod -R u+w "$workdir" && rm -rf "$workdir"   # mod cache is read-only
echo "Bundle: $OUT_ZIP"