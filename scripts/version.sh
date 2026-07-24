#!/usr/bin/env bash
# Read or bump MARKETING_VERSION / CURRENT_PROJECT_VERSION in project.yml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_YML="$ROOT/project.yml"
VERSION_XCCONFIG="$ROOT/Config/Version.xcconfig"

usage() {
  cat <<'EOF'
Usage:
  scripts/version.sh              # print marketing + build
  scripts/version.sh bump-build   # increment CURRENT_PROJECT_VERSION
  scripts/version.sh set X.Y.Z    # set MARKETING_VERSION (keeps build)
  scripts/version.sh set X.Y.Z N  # set marketing + build
EOF
}

read_marketing() {
  grep -E '^\s*MARKETING_VERSION:' "$PROJECT_YML" | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

read_build() {
  grep -E '^\s*CURRENT_PROJECT_VERSION:' "$PROJECT_YML" | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

write_versions() {
  local marketing="$1"
  local build="$2"
  python3 - "$PROJECT_YML" "$VERSION_XCCONFIG" "$marketing" "$build" <<'PY'
import pathlib, re, sys
yml, xcc, marketing, build = sys.argv[1:5]
text = pathlib.Path(yml).read_text()
text = re.sub(r'(MARKETING_VERSION:\s*)"[^"]+"', rf'\1"{marketing}"', text, count=1)
text = re.sub(r'(CURRENT_PROJECT_VERSION:\s*)"[^"]+"', rf'\1"{build}"', text, count=1)
pathlib.Path(yml).write_text(text)
pathlib.Path(xcc).write_text(
    "// Auto-synced by scripts/version.sh — prefer project.yml as source of truth.\n"
    f"MARKETING_VERSION = {marketing}\n"
    f"CURRENT_PROJECT_VERSION = {build}\n"
)
print(f"{marketing} ({build})")
PY
}

cmd="${1:-}"
case "$cmd" in
  "" )
    echo "$(read_marketing) ($(read_build))"
    ;;
  bump-build )
    marketing="$(read_marketing)"
    build="$(read_build)"
    write_versions "$marketing" "$((build + 1))"
    ;;
  set )
    marketing="${2:?marketing version required}"
    build="${3:-$(read_build)}"
    write_versions "$marketing" "$build"
    ;;
  -h|--help )
    usage
    ;;
  * )
    usage >&2
    exit 1
    ;;
esac
