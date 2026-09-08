#!/bin/bash

# fix_zoom.sh — disables all zoom and fixes sticky nav on mobile
# Run from root of repo: bash fix_zoom.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

FIXED=0
SKIPPED=0

fix_file() {
  local file="$1"
  local changed=false

  [[ "$file" == *.bak ]] && return

  echo -e "\n${CYAN}→ $file${NC}"

  python3 - "$file" << 'PY'
import sys, re

file_path = sys.argv[1]

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

original = content

# ── 1. Fix/add viewport (no zoom, no scale) ──────────────────────────────────
correct_viewport = '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">'

# Replace any existing viewport tag
vp_pattern = re.compile(r'<meta\s[^>]*name=["\']viewport["\'][^>]*/?>',re.IGNORECASE)
if vp_pattern.search(content):
    content = vp_pattern.sub(correct_viewport, content)
    print("  ~ viewport: replaced with no-zoom version")
else:
    # Insert after <head>
    head_pat = re.compile(r'(<head(?:\s[^>]*)?>)', re.IGNORECASE)
    content, n = head_pat.subn(r'\1\n  ' + correct_viewport, content, count=1)
    if n:
        print("  + viewport: added (no-zoom)")
    else:
        print("  ! could not find <head> to insert viewport")

# ── 2. Fix sticky nav: use 100dvw instead of 100vw, add touch-action ─────────
# The nav uses `width: 100vw` and `margin-left: calc(-50vw + 50%)`
# On mobile, 100vw includes scrollbar width and can exceed the viewport.
# 100dvw (dynamic viewport width) = always the actual visible width.

# Replace nav CSS width tricks with safe mobile values
nav_fix = '''
/* ── mobile-nav-fix ── */
nav {
  left: 0 !important;
  right: 0 !important;
  width: 100% !important;
  margin-left: 0 !important;
  max-width: 100vw !important;
  box-sizing: border-box !important;
}
/* Prevent pinch-zoom from breaking layout */
* { touch-action: pan-x pan-y; }
html { touch-action: pan-x pan-y; }
/* Prevent content from ever being wider than the screen */
html, body { max-width: 100%; overflow-x: hidden; }
'''

# Inject before </head>
if 'mobile-nav-fix' not in content:
    head_close = re.compile(r'</head>', re.IGNORECASE)
    content, n = head_close.subn('<style>' + nav_fix + '</style>\n</head>', content, count=1)
    if n:
        print("  + nav fix: injected")
    else:
        print("  ! could not find </head> for nav fix")
else:
    print("  ✓ nav fix already present")

if content != original:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("  ✓ saved")
    sys.exit(0)  # changed
else:
    print("  - no changes needed")
    sys.exit(1)  # unchanged
PY

  local exit_code=$?
  if [ $exit_code -eq 0 ]; then
    FIXED=$((FIXED + 1))
  else
    SKIPPED=$((SKIPPED + 1))
  fi
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
echo -e "  Done! ${GREEN}Fixed: $FIXED${NC} · Skipped: $SKIPPED"
echo "══════════════════════════════════════"
echo ""
echo "Changes applied to each page:"
echo "  • viewport: maximum-scale=1.0, user-scalable=no  → kills all pinch zoom"
echo "  • touch-action: pan-x pan-y                      → allows scroll, blocks zoom gesture"
echo "  • nav width: 100% + box-sizing                   → sticky bar fills screen properly"
echo "  • overflow-x: hidden                             → no horizontal bleed"
echo ""
echo "Push:"
echo "  git add -A && git commit -m 'fix: disable mobile zoom, fix sticky nav' && git push"
echo ""
