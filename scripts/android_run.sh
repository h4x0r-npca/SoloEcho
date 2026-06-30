#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/android_run.sh [device-id]

Examples:
  ./scripts/android_run.sh
  ./scripts/android_run.sh 192.168.219.100:44345
  ./scripts/android_run.sh adb-R3CY80JRZRA-KvuN3f._adb-tls-connect._tcp

This builds the Android debug APK, installs it on the selected device,
and launches SoloEcho. Android does not need a desktop OAuth client secret
or a command-line token.

For Android wireless debugging, the connected device id may be an adb mDNS
name instead of the phone's IP:port. If an IP:port is passed but ADB already
sees exactly one other wireless device, this script uses that connected device.
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

is_connected_device() {
  "$adb_bin" devices | awk -v id="$1" '
    NR > 1 && $1 == id && $2 == "device" { found = 1 }
    END { exit found ? 0 : 1 }
  '
}

connected_device_count() {
  "$adb_bin" devices | awk 'NR > 1 && $2 == "device" { count++ } END { print count + 0 }'
}

first_connected_device() {
  "$adb_bin" devices | awk 'NR > 1 && $2 == "device" { print $1; exit }'
}

device_id="${1:-}"
if [[ -z "$device_id" ]]; then
  device_count="$(connected_device_count)"
  device_id="$(first_connected_device)"
  if [[ -z "$device_id" ]]; then
    echo "No connected Android device found." >&2
    echo "Connect by USB or wireless debugging, then try again." >&2
    exit 1
  fi
  if [[ "$device_count" -gt 1 ]]; then
    echo "Multiple Android devices are connected. Using first device: $device_id"
    echo "Pass a device id to choose explicitly."
  fi
elif ! is_connected_device "$device_id"; then
  if [[ "$device_id" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    echo "ADB does not currently list $device_id. Trying adb connect..."
    "$adb_bin" connect "$device_id" || true
  fi

  if ! is_connected_device "$device_id"; then
    device_count="$(connected_device_count)"
    fallback_device_id="$(first_connected_device)"
    if [[ "$device_count" -eq 1 && -n "$fallback_device_id" ]]; then
      echo "Using already connected Android device: $fallback_device_id"
      echo "Tip: pass this id directly next time, or run the script with no arguments."
      device_id="$fallback_device_id"
    else
      echo "Android device was not found by ADB: $device_id" >&2
      echo "Currently connected devices:" >&2
      "$adb_bin" devices -l >&2
      echo "For wireless debugging, use the connection port, not the pairing port." >&2
      exit 1
    fi
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
