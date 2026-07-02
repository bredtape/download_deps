#!/usr/bin/env bash
# Usage: ./fetch-go-deps.sh <dir-with-go.txt-files> [output.zip]
# Each *.go.txt file: one module path per line (any @version suffix is ignored,
# latest is fetched). Produces a single bundle containing:
#   go/pkg/mod/...        shared module cache (incl. cache/download proxy tree)
#   projects/<name>/go.mod  one manifest per .go.txt, for jfrog rt go-publish
set -euo pipefail

SRC_DIR="$(realpath -e "${1:?dir with *.go.txt files}")"
OUT_ZIP="$(realpath -m "${2:-./go-deps-bundle.zip}")"

workdir="$(mktemp -d)"
export GOPATH="$workdir/go"
export GOMODCACHE="$GOPATH/pkg/mod"

for depfile in "$SRC_DIR"/*.go.txt; do
    project="$(basename "$depfile" .go.txt)"
    projdir="$workdir/projects/$project"
    mkdir -p "$projdir"
    (
        cd "$projdir"
        go mod init "local/$project" >/dev/null
        while IFS= read -r dep; do
            dep="${dep%%[[:space:]]*}"
            [[ -z "$dep" || "$dep" == \#* ]] && continue
            go get "${dep%%@*}@latest"
        done < "$depfile"
    )
    echo "OK: $project"
done

(cd "$workdir" && zip -qr "$OUT_ZIP" "go/pkg/mod" "projects")
chmod -R u+w "$workdir" && rm -rf "$workdir"   # mod cache is read-only
echo "Bundle: $OUT_ZIP"