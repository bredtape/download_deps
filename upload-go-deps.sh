unzip go-deps-bundle.zip -d /tmp/bundle
export GOPATH=/tmp/bundle/go
export GOMODCACHE=$GOPATH/pkg/mod

for proj in /tmp/bundle/projects/*/; do
    (cd "$proj" && jfrog rt go-publish go-local v1.0.0 --self=false --deps=ALL)
done