#!/bin/bash
set -euo pipefail

output_dir=$(mkdir -p "${1:?Usage: build-ipa.sh OUTPUT_DIR [SOURCE_DIR]}" && cd "$1" && pwd)
source_dir=${2:-$(cd "$(dirname "$0")/.." && pwd)}

# AltStore signs the archive with the recipient's Apple account.
xcodebuild archive \
  -workspace "$source_dir/Photochem.xcworkspace" \
  -scheme Photochem \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$output_dir/Photochem.xcarchive" \
  -derivedDataPath "$output_dir/DerivedData" \
  -skipPackagePluginValidation -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO

payload=$(mktemp -d "$output_dir/payload.XXXXXX")
trap 'rm -rf "$payload"' EXIT
mkdir "$payload/Payload"
ditto "$output_dir/Photochem.xcarchive/Products/Applications/PhotochemApp.app" \
  "$payload/Payload/PhotochemApp.app"
ditto -c -k --keepParent "$payload/Payload" "$output_dir/Photochem.ipa"
echo "IPA: $output_dir/Photochem.ipa"
