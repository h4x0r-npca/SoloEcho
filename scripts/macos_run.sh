#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/macos_run.sh -DesktopClientId "<desktop-client-id>" [-DesktopClientSecret "<desktop-client-secret>"] [-Mode run|build]

Options:
  -DesktopClientId, --desktop-client-id         Google OAuth desktop client id.
  -DesktopClientSecret, --desktop-client-secret Google OAuth desktop client secret.
  -Mode, --mode                                 run or build. Default: run.
  -h, --help                                    Show this help.

Environment variables are also supported:
  SOLOECHO_DESKTOP_CLIENT_ID
  SOLOECHO_DESKTOP_CLIENT_SECRET

If scripts/macos.local.env exists, it is loaded before arguments. Keep that
file local only; it is intentionally ignored by Git.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
local_env="$script_dir/macos.local.env"

if [[ -f "$local_env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$local_env"
  set +a
fi

desktop_client_id="${SOLOECHO_DESKTOP_CLIENT_ID:-}"
desktop_client_secret="${SOLOECHO_DESKTOP_CLIENT_SECRET:-}"
mode="run"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -DesktopClientId|--desktop-client-id)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      desktop_client_id="$2"
      shift 2
      ;;
    -DesktopClientSecret|--desktop-client-secret)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      desktop_client_secret="$2"
      shift 2
      ;;
    -Mode|--mode)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      mode="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$desktop_client_id" ]]; then
  echo "Desktop client id is required." >&2
  usage >&2
  exit 1
fi

if [[ "$mode" != "run" && "$mode" != "build" ]]; then
  echo "Mode must be either run or build: $mode" >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found on PATH." >&2
  exit 1
fi

cd "$repo_root"

dart_defines=(
  "--dart-define=SOLOECHO_DESKTOP_CLIENT_ID=$desktop_client_id"
)

if [[ -n "$desktop_client_secret" ]]; then
  dart_defines+=(
    "--dart-define=SOLOECHO_DESKTOP_CLIENT_SECRET=$desktop_client_secret"
  )
fi

flutter pub get

if [[ "$mode" == "build" ]]; then
  flutter build macos "${dart_defines[@]}"
else
  flutter run -d macos "${dart_defines[@]}"
fi
