#!/usr/bin/env bash
# =========================================================
# reinstall_widget_v2.sh
#
# Removes any existing Global Chat widget (old or new marker,
# any duplicate count) and cleanly reinserts the fixed v2
# widget (_gc_widget_snippet.html) that reads tren_session
# directly instead of relying on supabase-js session
# persistence.
#
# Does NOT touch the sidebar nav (already removed).
#
# USAGE:
#   ./reinstall_widget_v2.sh .
#
# REQUIRES (must sit next to this script):
#   _gc_widget_snippet.html   (the fixed v2 widget)
# =========================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET_SNIPPET="$SCRIPT_DIR/_gc_widget_snippet.html"

PAGES=(
  "overview"
  "ai-analysis"
  "journal"
  "live-signals"
  "signals"
  "upgrade"
)

ROOT_DIR="${1:-.}"

if [[ ! -f "$WIDGET_SNIPPET" ]]; then
  echo "Error: missing $WIDGET_SNIPPET" >&2
  exit 1
fi

for page in "${PAGES[@]}"; do
  file="$ROOT_DIR/$page/index.html"
  if [[ ! -f "$file" ]]; then
    echo "✘ not found: $file"
    continue
  fi

  python3 - "$file" "$WIDGET_SNIPPET" <<'PYEOF'
import re, sys

file_path, widget_path = sys.argv[1:3]

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

with open(widget_path, "r", encoding="utf-8") as f:
    widget_snippet = f.read()

# Remove the supabase-js CDN tag we added (any copy)
content = re.sub(
    r'\s*<script src="https://cdn\.jsdelivr\.net/npm/@supabase/supabase-js@2"></script>\s*\n?',
    "\n",
    content
)

# Remove every old-style widget block (starts with a ===== comment mentioning
# GLOBAL CHAT WIDGET, runs to its closing </script>)
pattern_old = re.compile(
    r'<!--\s*=+\s*\n?\s*TREN.{0,40}GLOBAL CHAT WIDGET.*?</script>\s*\n?',
    re.DOTALL
)
content, n1 = pattern_old.subn("", content)

# Remove every new-style widget block (starts directly with GC_WIDGET_MARKER)
pattern_new = re.compile(
    r'<!--\s*GC_WIDGET_MARKER.*?</script>\s*\n?',
    re.DOTALL
)
content, n2 = pattern_new.subn("", content)

removed = n1 + n2

# Insert the fresh widget once, right before the last </body>
last_body_idx = content.rfind("</body>")
if last_body_idx == -1:
    print(f"FAIL:no-closing-body-tag")
    sys.exit(0)

content = content[:last_body_idx] + widget_snippet + "\n" + content[last_body_idx:]

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"OK:removed={removed}")
PYEOF
done