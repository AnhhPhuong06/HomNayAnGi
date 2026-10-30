#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Open this project on a Mac with Flutter and Xcode installed." >&2
  exit 1
fi

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
export BYPASS_PERMISSION_LOCATION_ALWAYS=1

# Regenerate SDK paths, registrants and Swift packages on this Mac.
flutter pub get
flutter build ios --debug --config-only --no-codesign

# Launch the selected Xcode directly so package resolution inherits the flag.
# Quit an existing Xcode session before running this script.
xcode_developer_dir="$(xcode-select -p)"
xcode_executable="$xcode_developer_dir/../MacOS/Xcode"
if [[ ! -x "$xcode_executable" ]]; then
  echo "Select the full Xcode installation with xcode-select, then retry." >&2
  exit 1
fi
exec "$xcode_executable" "$PWD/ios/Runner.xcworkspace"
