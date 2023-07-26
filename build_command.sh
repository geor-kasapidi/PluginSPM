# STEP 1: build universal binary

swift package clean
swift build --product MyCommand -c release --arch arm64 --arch x86_64
rm -rf artifact && mkdir -p artifact/coolproject/bin
cp $(swift build --product MyCommand -c release --arch arm64 --arch x86_64 --show-bin-path)/MyCommand artifact/coolproject/bin/mycommand

# STEP 2: write artifact bundle manifest

cat <<EOF > artifact/info.json
{
  "schemaVersion": "1.0",
  "artifacts": {
    "mycommand": {
      "version": "0.0.1",
      "type": "executable",
      "variants": [
        {
          "path": "coolproject/bin/mycommand",
          "supportedTriples": [
            "x86_64-apple-macosx",
            "arm64-apple-macosx"
          ]
        }
      ]
    }
  }
}
EOF

# STEP 3: create artifact bundle zip

cd artifact
zip -r ../mycommand.artifactbundle.zip . -x '**/.*' -x '**/__MACOSX'
cd ..
rm -rf artifact
