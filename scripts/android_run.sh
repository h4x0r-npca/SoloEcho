#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/android_run.sh [device-id]

Examples:
  ./scripts/android_run.sh
  ./scripts/android_run.sh 192.168.219.100:44345

This builds the Android debug APK, installs it on the selected device,
and launches SoloEcho. Android does not need a desktop OAuth client secret
or a command-line token.
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

adb_bin="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
if [[ ! -x "$adb_bin" ]]; then
  if command -v adb >/dev/null 2>&1; then
    adb_bin="$(command -v adb)"
  else
    echo "adb was not found. Install Android platform-tools or set ANDROID_HOME." >&2
    exit 1
  fi
fi

device_id="${1:-}"
if [[ -z "$device_id" ]]; then
  device_count="$("$adb_bin" devices | awk 'NR > 1 && $2 == "device" { count++ } END { print count + 0 }')"
  device_id="$("$adb_bin" devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"
  if [[ -z "$device_id" ]]; then
    echo "No connected Android device found." >&2
    echo "Connect by USB or wireless debugging, then try again." >&2
    exit 1
  fi
  if [[ "$device_count" -gt 1 ]]; then
    echo "Multiple Android devices are connected. Using first device: $device_id"
    echo "Pass a device id to choose explicitly."
  fi
fi

apk_path="build/app/outputs/flutter-apk/app-debug.apk"

echo "Building Android debug APK..."
flutter build apk --debug

echo "Installing on $device_id..."
"$adb_bin" -s "$device_id" install -r "$apk_path"

echo "Launching SoloEcho..."
"$adb_bin" -s "$device_id" shell monkey \
  -p com.soloecho.app \
  -c android.intent.category.LAUNCHER \
  1 >/dev/null

echo "SoloEcho is running on $device_id."
