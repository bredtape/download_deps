unzip go-deps-bundle.zip -d /tmp/bundle
cd /tmp/bundle/download

for ext in info mod zip; do
    jf rt u "*.${ext}" go-external/ --flat=false --exclusions "*/@latest"
done