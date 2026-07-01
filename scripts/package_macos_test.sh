#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/package_macos_test.sh
  ./scripts/package_macos_test.sh -DesktopClientId "<desktop-client-id>" [-DesktopClientSecret "<desktop-client-secret>"]

Options:
  -DesktopClientId, --desktop-client-id         Google OAuth desktop client id.
  -DesktopClientSecret, --desktop-client-secret Google OAuth desktop client secret.
  -Name, --name                                 Package folder/zip name. Default: SoloEcho-macOS-test
  -Configuration, --configuration               release or debug. Default: release.
  -h, --help                                    Show this help.

Environment variables are also supported:
  SOLOECHO_DESKTOP_CLIENT_ID
  SOLOECHO_DESKTOP_CLIENT_SECRET
  SOLOECHO_FLUTTER_BUILD_DIR

For repeated local packaging, create scripts/macos.local.env and then run
without arguments. Keep that file local only; it is intentionally ignored by Git.
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
package_name="SoloEcho-macOS-test"
configuration="release"
flutter_build_dir="${SOLOECHO_FLUTTER_BUILD_DIR:-/private/tmp/soloecho_flutter_build}"

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
    -Name|--name)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      package_name="$2"
      shift 2
      ;;
    -Configuration|--configuration)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      configuration="$2"
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
  echo "Pass -DesktopClientId once, or save SOLOECHO_DESKTOP_CLIENT_ID in scripts/macos.local.env." >&2
  usage >&2
  exit 1
fi

if [[ "$package_name" == *"/"* || "$package_name" == "." || "$package_name" == ".." ]]; then
  echo "Package name must be a simple folder name: $package_name" >&2
  exit 1
fi

case "$configuration" in
  release)
    build_flag="--release"
    product_configuration="Release"
    ;;
  debug)
    build_flag="--debug"
    product_configuration="Debug"
    ;;
  *)
    echo "Configuration must be either release or debug: $configuration" >&2
    exit 1
    ;;
esac

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found on PATH." >&2
  exit 1
fi

if ! command -v ditto >/dev/null 2>&1; then
  echo "ditto was not found on PATH." >&2
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

echo "Building SoloEcho for macOS ($configuration)..."
if ! env FLUTTER_BUILD_DIR="$flutter_build_dir" \
  flutter build macos "$build_flag" "${dart_defines[@]}"; then
  echo "macOS build failed. Cleaning Flutter/Xcode build outputs and retrying once..." >&2
  flutter clean
  env FLUTTER_BUILD_DIR="$flutter_build_dir" \
    flutter build macos "$build_flag" "${dart_defines[@]}"
fi

app_path="$repo_root/build/macos/Build/Products/$product_configuration/SoloEcho.app"
if [[ ! -d "$app_path" ]]; then
  echo "Built app was not found: $app_path" >&2
  exit 1
fi

dist_dir="$repo_root/dist"
package_dir="$dist_dir/$package_name"
zip_path="$dist_dir/$package_name.zip"
readme_path="$package_dir/README_KO.txt"

rm -rf "$package_dir" "$zip_path"
mkdir -p "$package_dir"

ditto "$app_path" "$package_dir/SoloEcho.app"

echo "Preparing local test signature..."
xattr -cr "$package_dir/SoloEcho.app"
while IFS= read -r -d '' framework; do
  codesign --force --sign - "$framework"
done < <(find "$package_dir/SoloEcho.app/Contents/Frameworks" -type d -name "*.framework" -print0)
codesign --force --sign - \
  --entitlements "$repo_root/macos/Runner/Release.entitlements" \
  "$package_dir/SoloEcho.app"
codesign --verify --deep --strict --verbose=2 "$package_dir/SoloEcho.app"
entitlements_output="$(codesign -d --entitlements :- "$package_dir/SoloEcho.app" 2>/dev/null || true)"
if [[ "$entitlements_output" != *"<key>com.apple.security.network.client</key>"* ]]; then
  echo "Packaged app is missing the macOS network client entitlement." >&2
  exit 1
fi

git_commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
dirty_note=""
if [[ -n "$(git status --porcelain --untracked-files=no 2>/dev/null || true)" ]]; then
  dirty_note=" + 로컬 미커밋 변경 포함"
fi
build_time="$(date '+%Y-%m-%d %H:%M:%S %Z')"

cat > "$readme_path" <<EOF
SoloEcho macOS 테스트 앱 사용 안내
==================================

빌드 정보
- 빌드 시각: $build_time
- 빌드 기준: $git_commit$dirty_note
- 앱 파일: SoloEcho.app

실행 방법
1. 이 zip 파일을 압축 해제합니다.
2. SoloEcho.app을 더블클릭해서 실행합니다.
3. macOS가 "확인되지 않은 개발자"라고 막으면 SoloEcho.app을 우클릭한 뒤 "열기"를 선택합니다.
4. 그래도 막히면 시스템 설정 > 개인정보 보호 및 보안에서 SoloEcho 실행 허용을 누른 뒤 다시 엽니다.

주의사항
- 이 파일은 테스트용 빌드입니다. App Store 배포나 Apple 공증(notarization)을 거친 앱이 아닙니다.
- Google 로그인과 Google Drive/Sheets 저장을 위해 인터넷 연결이 필요합니다.
- 기록 데이터는 사용자의 Google Drive 안에 생성되는 SoloEcho 폴더와 SoloEcho Timeline 스프레드시트에 저장됩니다.
- 테스트 중 문제가 생기면 오류 문구와 macOS 버전, 사용한 Google 계정을 함께 전달해 주세요.

실행이 계속 막힐 때의 마지막 방법
터미널에서 압축을 푼 폴더로 이동한 뒤 아래 명령을 실행하고 다시 열어보세요.

  xattr -dr com.apple.quarantine SoloEcho.app

실행은 되지만 저장/동기화 중 CERTIFICATE_VERIFY_FAILED가 나오면
기존에 압축 해제한 앱을 완전히 지우고 최신 zip을 다시 압축 해제해 주세요.
이 테스트 빌드는 패키징 단계에서 네트워크 권한을 포함해 로컬 테스트 서명을 다시 적용합니다.

EOF

find "$package_dir" -name .DS_Store -delete

ditto -c -k --sequesterRsrc --keepParent "$package_dir" "$zip_path"

echo "Created package:"
echo "  $zip_path"
echo
echo "Contents:"
find "$package_dir" -maxdepth 2 -print | sed "s#^$dist_dir/##"
