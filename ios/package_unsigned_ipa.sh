#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "IPA packaging requires macOS (ditto and zip)." >&2
  exit 1
fi

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
app_path="$PWD/build/ios/iphoneos/Runner.app"
output_dir="$PWD/build/ios/ipa"
if [[ ! -f "$app_path/Info.plist" || ! -f "$app_path/Runner" ]]; then
  echo "Missing Runner.app. Run flutter build ios --release --no-codesign first." >&2
  exit 1
fi

mkdir -p "$output_dir"
package_dir="$(mktemp -d "$output_dir/package.XXXXXX")"
trap 'rm -rf "$package_dir"' EXIT
mkdir -p "$package_dir/Payload"
# Preserve executable permissions and framework symlinks in the app bundle.
ditto "$app_path" "$package_dir/Payload/Runner.app"
(
  cd "$package_dir"
  zip -qry hom_nay_an_gi-unsigned.ipa Payload
  unzip -tq hom_nay_an_gi-unsigned.ipa
)
mv -f "$package_dir/hom_nay_an_gi-unsigned.ipa" "$output_dir/"
echo "Unsigned IPA: $output_dir/hom_nay_an_gi-unsigned.ipa"
