#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/ios_run.sh [device-id]

Examples:
  ./scripts/ios_run.sh
  ./scripts/ios_run.sh "iPhone 16 Pro"

This runs SoloEcho on an iOS simulator or connected iPhone.
Google login on iOS requires ios/Flutter/GoogleSignIn.local.xcconfig.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found on PATH." >&2
  exit 1
fi

device_id="${1:-ios}"

if [[ ! -f ios/Flutter/GoogleSignIn.local.xcconfig ]]; then
  echo "Warning: ios/Flutter/GoogleSignIn.local.xcconfig was not found." >&2
  echo "The app can launch, but Google login will fail until iOS OAuth values are set." >&2
fi

flutter pub get
flutter run -d "$device_id"
