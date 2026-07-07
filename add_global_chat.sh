#!/usr/bin/env bash
# =========================================================
# add_global_chat.sh
#
# Inserts the Global Chat nav item + widget into the
# index.html of specific dashboard page folders.
#
# Safe to re-run: files that already contain the widget
# (GC_WIDGET_MARKER) are skipped automatically.
#
# USAGE:
#   ./add_global_chat.sh /path/to/repo/root
#
#   The repo root should contain these page folders,
#   each with its own index.html:
#     overview/index.html
#     ai-analysis/index.html
#     journal/index.html
#     live-signals/index.html
#     signals/index.html
#     upgrade/index.html
#
#   To target a different set of pages, edit the PAGES
#   array below.
#
# REQUIRES (must sit next to this script):
#   _gc_nav_snippet.html
#   _gc_widget_snippet.html
#
# REQUIRES per target page:
#   - a sidebar element with class="s-nav"
#   - a closing </body> tag
#   - SUPABASE_AUTH_URL / SUPABASE_AUTH_KEY already defined
#     earlier in the page (same as overview/index.html)
# =========================================================

set -euo pipefail

# ---- Pages to update (folder names, each containing index.html) ----
PAGES=(
  "overview"
  "ai-analysis"
  "journal"
  "live-signals"
  "signals"
  "upgrade"
)
# ----------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-.}"

NAV_SNIPPET="$SCRIPT_DIR/_gc_nav_snippet.html"
WIDGET_SNIPPET="$SCRIPT_DIR/_gc_widget_snippet.html"

if [[ ! -f "$NAV_SNIPPET" ]]; then
  echo "Error: missing $NAV_SNIPPET" >&2
  exit 1
fi
if [[ ! -f "$WIDGET_SNIPPET" ]]; then
  echo "Error: missing $WIDGET_SNIPPET" >&2
  exit 1
fi
if [[ ! -d "$ROOT_DIR" ]]; then
  echo "Error: root directory '$ROOT_DIR' does not exist" >&2
  exit 1
fi
if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required but not found" >&2
  exit 1
fi

echo "Targeting ${#PAGES[@]} page(s) under '$ROOT_DIR'"
echo "---"

updated=0
skipped=0
failed=0
missing=0

for page in "${PAGES[@]}"; do
  file="$ROOT_DIR/$page/index.html"

  if [[ ! -f "$file" ]]; then
    echo "✘ not found: $file"
    missing=$((missing + 1))
    continue
  fi

  status=$(python3 - "$file" "$NAV_SNIPPET" "$WIDGET_SNIPPET" <<'PYEOF'
import sys

file_path, nav_path, widget_path = sys.argv[1:4]

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

if "GC_WIDGET_MARKER" in content:
    print("SKIP")
    sys.exit(0)

if "</body>" not in content:
    print("FAIL:no-closing-body-tag")
    sys.exit(0)

with open(nav_path, "r", encoding="utf-8") as f:
    nav_snippet = f.read()
with open(widget_path, "r", encoding="utf-8") as f:
    widget_snippet = f.read()

# Insert nav item as first child of the sidebar nav, if present
nav_anchor = 'class="s-nav"'
idx = content.find(nav_anchor)
if idx != -1:
    tag_end = content.find(">", idx)
    if tag_end != -1:
        insert_at = tag_end + 1
        content = content[:insert_at] + "\n" + nav_snippet + content[insert_at:]
else:
    print("WARN:no-s-nav-found (widget added, no nav link)")

# Insert widget block right before the LAST closing </body>
last_body_idx = content.rfind("</body>")
content = content[:last_body_idx] + widget_snippet + "\n" + content[last_body_idx:]

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("OK")
PYEOF
)

  case "$status" in
    OK)
      echo "✔ updated: $file"
      updated=$((updated + 1))
      ;;
    SKIP)
      echo "⏭ skipped (already has widget): $file"
      skipped=$((skipped + 1))
      ;;
    FAIL:*)
      echo "✘ failed (${status#FAIL:}): $file"
      failed=$((failed + 1))
      ;;
    WARN:*)
      echo "⚠ updated with warning (${status#WARN:}): $file"
      updated=$((updated + 1))
      ;;
    *)
      echo "✘ unexpected result for $file: $status"
      failed=$((failed + 1))
      ;;
  esac
done

echo "---"
echo "Done. Updated: $updated | Skipped: $skipped | Failed: $failed | Not found: $missing"