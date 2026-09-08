#!/bin/bash

# fix_zoom.sh — fix mobile zoom by removing nav overflow + locking viewport
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

# ── 1. Directly replace "width: 100vw" with "width: 100%" everywhere in nav.
# Simple string replace — no complex regex needed.
if 'width: 100vw' in content:
    content = content.replace('width: 100vw', 'width: 100%')
    changed.append('width: 100vw → 100%')

# ── 2. Remove "margin-left: calc(-50vw + 50%)" — only needed with 100vw.
for variant in [
    'margin-left: calc(-50vw + 50%);',
    'margin-left: calc(-50vw + 50%)',
    'margin-left:calc(-50vw + 50%);',
    'margin-left:calc(-50vw + 50%)',
]:
    if variant in content:
        content = content.replace(variant, '')
        changed.append('margin-left: calc(-50vw+50%) removed')
        break

# ── 3. Add "html { overflow-x: hidden; }" if not present.
# body already has it in your CSS; html needs it too to prevent root overflow.
if not re.search(r'html\s*\{[^}]*overflow-x\s*:\s*hidden', content):
    # Inject it right before the body { rule
    content = re.sub(
        r'(body\s*\{)',
        'html { overflow-x: hidden; }\n\\1',
        content,
        count=1
    )
    changed.append('html { overflow-x: hidden } added')

# ── 4. Fix viewport: add user-scalable=no if missing.
vp_pat = re.compile(r'<meta\s+name=["\']viewport["\'][^>]*/?>',re.IGNORECASE)
correct_vp = '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">'
m = vp_pat.search(content)
if m:
    if 'user-scalable=no' not in m.group(0):
        content = vp_pat.sub(correct_vp, content)
        changed.append('viewport: user-scalable=no added')
    # else already correct, no change
else:
    head_pat = re.compile(r'(<head(?:\s[^>]*)?>)', re.IGNORECASE)
    content, n = head_pat.subn(r'\1\n  ' + correct_vp, content, count=1)
    if n:
        changed.append('viewport tag inserted')

if content != original:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    for c in changed:
        print(f'  ✓ {c}')
    print('  → saved')
    sys.exit(0)
else:
    print('  - no changes needed')
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
echo "Push:"
echo "  git add -A && git commit -m 'fix: remove nav overflow causing mobile zoom' && git push"
echo ""