#!/bin/bash

# fix_zoom.sh — mobile-only zoom disable
# Run from repo root: bash fix_zoom.sh

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

FIXED=0
SKIPPED=0

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
  [[ "$file" == *.bak ]] && continue
  echo -e "\n${CYAN}→ $file${NC}"

  python3 - "$file" << 'PYEOF'
import re, sys

path = sys.argv[1]

with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Skip if already patched
if 'maxTouchPoints' in content or 'user-scalable=no' in content:
    print("  ✓ already patched — skipping")
    sys.exit(1)

snippet = (
    '<script>'
    '(function(){'
    'if(navigator.maxTouchPoints>0||"ontouchstart" in window){'
    'var v=document.querySelector("meta[name=viewport]");'
    'if(v){v.setAttribute("content","width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no");}'
    'else{var m=document.createElement("meta");'
    'm.name="viewport";'
    'm.content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no";'
    'if(document.head)document.head.insertBefore(m,document.head.firstChild);}'
    '}})();'
    '</script>'
)

original = content

# Insert right after <head> opening tag
head_open = re.compile(r'(<head(?:\s[^>]*)?>)', re.IGNORECASE)
m = head_open.search(content)
if m:
    pos = m.end()
    content = content[:pos] + snippet + content[pos:]
    print("  + snippet injected after <head>")
else:
    # No <head> — insert before first <meta>, <script>, <style>, or <link>
    first = re.compile(r'(<(?:meta|script|style|link)[\s>])', re.IGNORECASE)
    m = first.search(content)
    if m:
        pos = m.start()
        content = content[:pos] + snippet + content[pos:]
        print("  + snippet injected before first tag")
    else:
        # Last resort: prepend
        content = snippet + content
        print("  + snippet prepended")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✓ saved")
sys.exit(0)
PYEOF

  code=$?
  [ $code -eq 0 ] && FIXED=$((FIXED+1)) || SKIPPED=$((SKIPPED+1))
done

echo ""
echo "══════════════════════════════════════"
echo -e "  ${GREEN}Fixed: $FIXED${NC}  ·  Skipped: $SKIPPED"
echo "══════════════════════════════════════"
echo ""
echo "Push:"
echo "  git add -A && git commit -m 'fix: disable zoom on mobile/tablet only' && git push"
echo ""