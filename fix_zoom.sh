#!/bin/bash

# fix_zoom.sh — fix the actual overflow causing mobile zoom, across all pages
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

original = content

changed = []

# ── 1. Fix nav: replace "width: 100vw" with "width: 100%" ────────────────────
# 100vw includes the scrollbar and causes overflow → zoom
# Must be scoped to nav rules only (not other elements)
# Match "width: 100vw" inside a nav { } block
nav_block = re.compile(
    r'(nav\s*\{[^}]*?)width\s*:\s*100vw([^}]*\})',
    re.DOTALL
)
new, n = nav_block.subn(r'\1width: 100%\2', content)
if n:
    content = new
    changed.append(f"nav width: 100vw → 100% ({n} instance(s))")

# ── 2. Fix nav: remove "margin-left: calc(-50vw + 50%)" ─────────────────────
# This trick centres a 100vw element — not needed once width is 100%
nav_margin = re.compile(
    r'(nav\s*\{[^}]*?)margin-left\s*:\s*calc\(-50vw[^;]*\);?([^}]*\})',
    re.DOTALL
)
new, n = nav_margin.subn(r'\1\2', content)
if n:
    content = new
    changed.append(f"nav margin-left: calc(-50vw+50%) removed ({n} instance(s))")

# ── 3. Ensure html element has overflow-x: hidden ────────────────────────────
# body already has it, but html also needs it to truly prevent scroll
if 'overflow-x: hidden' in content and re.search(r'html\s*\{[^}]*overflow-x\s*:\s*hidden', content):
    changed.append("html overflow-x already set")
else:
    # Add it after the existing body overflow-x hidden rule, or in a new block
    body_overflow = re.compile(r'(body\s*\{[^}]*?)(overflow-x\s*:\s*hidden\s*;?)', re.DOTALL)
    if body_overflow.search(content):
        # Insert an html rule right before the body block that has overflow-x
        body_block = re.compile(r'(body\s*\{)', re.DOTALL)
        new, n = body_block.subn(r'html { overflow-x: hidden; }\n\1', content, count=1)
        if n and new != content:
            content = new
            changed.append("html { overflow-x: hidden } added")

# ── 4. Fix viewport: ensure maximum-scale=1.0, user-scalable=no ──────────────
vp = re.compile(r'<meta\s+name=["\']viewport["\'][^>]*/?>',re.IGNORECASE)
correct = '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">'
m = vp.search(content)
if m:
    if 'user-scalable=no' not in m.group(0):
        content = vp.sub(correct, content)
        changed.append("viewport: added user-scalable=no")
    else:
        changed.append("viewport already correct")
else:
    # No viewport tag — inject after <head>
    head = re.compile(r'(<head(?:\s[^>]*)?>)', re.IGNORECASE)
    content, n = head.subn(r'\1\n  ' + correct, content, count=1)
    if n:
        changed.append("viewport tag added")

if content != original:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    for c in changed:
        print(f"  ✓ {c}")
    print("  → saved")
    sys.exit(0)
else:
    print("  - no changes needed")
    sys.exit(1)
PYEOF

  code=$?
  [ $code -eq 0 ] && FIXED=$((FIXED+1)) || SKIPPED=$((SKIPPED+1))
done

echo ""
echo "══════════════════════════════════════"
echo -e "  ${GREEN}Fixed: $FIXED${NC}  ·  Already OK: $SKIPPED"
echo "══════════════════════════════════════"
echo ""
echo "Root cause fixed:"
echo "  • nav width: 100vw → 100%  (100vw caused horizontal overflow)"
echo "  • nav margin-left: calc(-50vw+50%) removed  (not needed anymore)"
echo "  • html overflow-x: hidden  (stops the overflow reaching the root)"
echo "  • viewport user-scalable=no  (belt-and-suspenders)"
echo ""
echo "Push:"
echo "  git add -A && git commit -m 'fix: remove nav overflow causing mobile zoom' && git push"
echo ""