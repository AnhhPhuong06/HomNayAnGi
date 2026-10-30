#!/usr/bin/env bash
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Build iOS requires macOS and Xcode." >&2
  exit 1
fi
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
# SPM compiles geolocator without the unused Always Location permission API.
export BYPASS_PERMISSION_LOCATION_ALWAYS=1
flutter pub get
flutter build ipa "$@"
