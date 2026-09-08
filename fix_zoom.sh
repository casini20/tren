#!/bin/bash

# fix_zoom.sh — disable all mobile zoom + fix sticky nav overflow
# Run from repo root: bash fix_zoom.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

FIXED=0
SKIPPED=0

fix_file() {
  local file="$1"
  [[ "$file" == *.bak ]] && return

  echo -e "\n${CYAN}→ $file${NC}"

  python3 << PYEOF
import re, sys

file_path = "$file"

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

original = content

# ── 1. Viewport: always replace with the strict no-zoom version ───────────────
# We unconditionally replace whatever is there — this catches files that have
# initial-scale=1.0 but are missing maximum-scale and user-scalable.
correct_vp = '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">'

vp_pat = re.compile(r'<meta\s+name=["\']viewport["\'][^>]*/?>',re.IGNORECASE)
if vp_pat.search(content):
    new = vp_pat.sub(correct_vp, content)
    if new != content:
        content = new
        print("  ~ viewport updated (added maximum-scale=1.0 user-scalable=no)")
    else:
        print("  ✓ viewport already correct")
else:
    # No viewport tag at all — inject after <head>
    head_pat = re.compile(r'(<head(?:\s[^>]*)?>)', re.IGNORECASE)
    content, n = head_pat.subn(r'\1\n  ' + correct_vp, content, count=1)
    if n:
        print("  + viewport added")
    else:
        print("  ! no <head> tag found — skipping viewport")

# ── 2. Nav + overflow CSS — inject once before </head> ────────────────────────
nav_css = """<style id="mobile-zoom-fix">
  /* Prevent pinch-zoom gesture at the browser level */
  html { touch-action: pan-x pan-y; }
  * { touch-action: pan-x pan-y; }

  /* Prevent any content from bleeding wider than the screen */
  html, body { max-width: 100%; overflow-x: hidden; }

  /* Fix sticky nav: 100vw can exceed the visible width on mobile (includes
     scrollbar). Using width:100% + box-sizing keeps it flush to the screen. */
  nav {
    left: 0 !important;
    right: 0 !important;
    width: 100% !important;
    margin-left: 0 !important;
    max-width: 100vw !important;
    box-sizing: border-box !important;
  }

  /* Prevent images / svgs from overflowing */
  img, svg, video, iframe { max-width: 100%; }
</style>"""

if 'id="mobile-zoom-fix"' not in content:
    head_close = re.compile(r'(</head>)', re.IGNORECASE)
    content, n = head_close.subn(nav_css + r'\n\1', content, count=1)
    if n:
        print("  + mobile CSS injected")
    else:
        # No </head>? Try before </body>
        body_close = re.compile(r'(</body>)', re.IGNORECASE)
        content, n = body_close.subn(nav_css + r'\n\1', content, count=1)
        if n:
            print("  + mobile CSS injected (before </body>)")
        else:
            content += '\n' + nav_css
            print("  + mobile CSS appended at end")
else:
    print("  ✓ mobile CSS already present")

if content != original:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  ✓ saved")
    sys.exit(0)
else:
    print("  - no changes made")
    sys.exit(1)
PYEOF

  local code=$?
  [ $code -eq 0 ] && FIXED=$((FIXED+1)) || SKIPPED=$((SKIPPED+1))
}

echo ""
echo "══════════════════════════════════════════"
echo "  fix_zoom.sh · casini20/tren"
echo "══════════════════════════════════════════"
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
echo "══════════════════════════════════════════"
echo -e "  ${GREEN}Fixed: $FIXED${NC}  ·  Already OK: $SKIPPED"
echo "══════════════════════════════════════════"
echo ""
echo "What was applied to every page:"
echo "  • maximum-scale=1.0, user-scalable=no  → kills pinch zoom"
echo "  • touch-action: pan-x pan-y            → blocks zoom gesture at OS level"
echo "  • nav width: 100% + box-sizing         → sticky bar fits screen correctly"
echo "  • overflow-x: hidden on html/body      → no horizontal bleed"
echo ""
echo "Now push:"
echo "  git pull --rebase && git add -A && git commit -m 'fix: disable zoom, fix sticky nav' && git push"
echo ""