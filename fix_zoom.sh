#!/bin/bash

# fix_zoom.sh — mobile-only zoom disable, safe for all page structures
# Run from repo root: bash fix_zoom.sh

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

FIXED=0
SKIPPED=0

# The JS snippet: detects touch device and rewrites the viewport meta at runtime.
# This means desktop users are completely unaffected.
# It runs immediately (no DOMContentLoaded delay) to avoid flash of zoomable state.
SNIPPET='<script>
(function(){
  var isTouchDevice = (navigator.maxTouchPoints > 0 || "ontouchstart" in window);
  if (isTouchDevice) {
    var vp = document.querySelector("meta[name=viewport]");
    if (vp) {
      vp.setAttribute("content", "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no");
    } else {
      var m = document.createElement("meta");
      m.name = "viewport";
      m.content = "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no";
      document.head && document.head.appendChild(m);
    }
  }
})();
</script>'

fix_file() {
  local file="$1"
  [[ "$file" == *.bak ]] && return

  echo -e "\n${CYAN}→ $file${NC}"

  python3 << PYEOF
import re, sys

path = "$file"

with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

original = content

snippet = """$SNIPPET"""

# Skip if already patched
if 'user-scalable=no' in content or 'mobile-zoom-fix' in content or 'maxTouchPoints' in content:
    print("  ✓ already patched — skipping")
    sys.exit(1)

# Try to insert right after <head> opening tag (best position — runs before anything else)
head_open = re.compile(r'(<head(?:\s[^>]*)?>)', re.IGNORECASE)
m = head_open.search(content)
if m:
    insert_at = m.end()
    content = content[:insert_at] + '\n' + snippet + content[insert_at:]
    print("  + snippet injected after <head>")
else:
    # No <head> — try before first <script> or <style>
    first_tag = re.compile(r'(<(?:script|style|link|meta)[\s>])', re.IGNORECASE)
    m = first_tag.search(content)
    if m:
        insert_at = m.start()
        content = content[:insert_at] + snippet + '\n' + content[insert_at:]
        print("  + snippet injected before first script/style tag")
    else:
        print("  ! could not find safe injection point — skipping")
        sys.exit(1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✓ saved")
sys.exit(0)
PYEOF

  local code=$?
  [ $code -eq 0 ] && FIXED=$((FIXED+1)) || SKIPPED=$((SKIPPED+1))
}

echo ""
echo "══════════════════════════════════════"
echo "  fix_zoom.sh · casini20/tren"
echo "══════════════════════════════════════"
echo ""

mapfile -t HTML_FILES < <(find . \
  -type f \( -iname "*.html" -o -iname "*.htm" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -name "*.bak" \
  | sort)

if [ ${#HTML_FILES[@]} -eq 0 ]; then
  echo "No HTML files found. Run from repo root."
  exit 1
fi

echo "Found ${#HTML_FILES[@]} HTML files"

for file in "${HTML_FILES[@]}"; do
  fix_file "$file"
done

echo ""
echo "══════════════════════════════════════"
echo -e "  ${GREEN}Fixed: $FIXED${NC}  ·  Skipped: $SKIPPED"
echo "══════════════════════════════════════"
echo ""
echo "How it works:"
echo "  • Injects a tiny JS snippet into each page"
echo "  • On page load it checks: is this a touch device?"
echo "  • If yes → sets maximum-scale=1.0, user-scalable=no on the viewport"
echo "  • If no  → viewport is untouched, desktop zoom works normally"
echo "  • Does NOT inject any CSS or modify page layout"
echo ""
echo "Now push:"
echo "  git add -A && git commit -m 'fix: disable zoom on mobile/tablet only' && git push"
echo ""