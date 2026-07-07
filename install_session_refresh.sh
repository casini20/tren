#!/usr/bin/env bash
# =========================================================
# install_session_refresh.sh
#
# Inserts the tren_session auto-refresh script into the
# six dashboard pages, right before </body>. Safe to re-run
# (skips files that already have it).
#
# USAGE:
#   ./install_session_refresh.sh .
#
# REQUIRES (must sit next to this script):
#   _gc_refresh_snippet.html
#
# REQUIRES per page:
#   - SUPABASE_AUTH_URL / SUPABASE_AUTH_KEY already defined
#   - The login page must be the UPDATED version that stores
#     refresh_token + expires_at in tren_session, otherwise
#     this has nothing to refresh.
# =========================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REFRESH_SNIPPET="$SCRIPT_DIR/_gc_refresh_snippet.html"

PAGES=(
  "overview"
  "ai-analysis"
  "journal"
  "live-signals"
  "signals"
  "upgrade"
)

ROOT_DIR="${1:-.}"

if [[ ! -f "$REFRESH_SNIPPET" ]]; then
  echo "Error: missing $REFRESH_SNIPPET" >&2
  exit 1
fi

for page in "${PAGES[@]}"; do
  file="$ROOT_DIR/$page/index.html"
  if [[ ! -f "$file" ]]; then
    echo "✘ not found: $file"
    continue
  fi

  status=$(python3 - "$file" "$REFRESH_SNIPPET" <<'PYEOF'
import sys

file_path, snippet_path = sys.argv[1:3]

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

if "GC_REFRESH_MARKER" in content:
    print("SKIP")
    sys.exit(0)

if "</body>" not in content:
    print("FAIL:no-closing-body-tag")
    sys.exit(0)

with open(snippet_path, "r", encoding="utf-8") as f:
    snippet = f.read()

last_body_idx = content.rfind("</body>")
content = content[:last_body_idx] + snippet + "\n" + content[last_body_idx:]

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("OK")
PYEOF
)

  case "$status" in
    OK) echo "✔ updated: $file" ;;
    SKIP) echo "⏭ skipped (already has refresh script): $file" ;;
    FAIL:*) echo "✘ failed (${status#FAIL:}): $file" ;;
    *) echo "✘ unexpected result for $file: $status" ;;
  esac
done