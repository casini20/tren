#!/usr/bin/env bash
# ================================================================
#  add_wallet_nav.sh  —  v3 (debug-friendly)
# ================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; GREY='\033[0;37m'; RED='\033[0;31m'; NC='\033[0m'
UPDATED=0; SKIPPED=0; FAILED=0

echo "Scanning from: $(pwd)"
echo "HTML files found:"
find . -name "*.html" -not -path "*/node_modules/*" -not -path "*/.git/*" | sort
echo "---"

while IFS= read -r -d '' file; do

  # Skip wallet-tracker page
  if [[ "$file" == *"wallet-tracker"* ]]; then
    echo -e "${GREY}SKIP (wallet-tracker)${NC}  $file"
    ((SKIPPED++)); continue
  fi

  # Skip if already injected
  if grep -qF 'wallet-tracker' "$file" 2>/dev/null; then
    echo -e "${YELLOW}SKIP (already done)${NC}    $file"
    ((SKIPPED++)); continue
  fi

  # Check if it has navTo at all
  if ! grep -qF 'navTo' "$file" 2>/dev/null; then
    echo -e "${GREY}SKIP (no navTo)${NC}        $file"
    ((SKIPPED++)); continue
  fi

  echo "PROCESSING: $file"

  python3 - "$file" <<'PYEOF'
import sys, pathlib, re

path = pathlib.Path(sys.argv[1])
content = path.read_text(encoding='utf-8')

NAV_ITEM = """
      <a class="s-item" onclick="navTo('https://trenai.vercel.app/wallet-tracker')">
        <span class="s-ic">&#x1F45B;</span><span>Wallet Tracker</span>
        <span style="margin-left:auto;font-size:9px;font-weight:700;padding:2px 6px;border-radius:4px;background:rgba(37,99,235,.18);border:0.5px solid rgba(37,99,235,.35);color:var(--al);">NEW</span>
      </a>"""

anchors = [
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/indicator['\"][^>]*>.*?</a>)", re.DOTALL), 'after'),
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/autosignals['\"][^>]*>.*?</a>)", re.DOTALL), 'after'),
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/trenbot['\"][^>]*>.*?</a>)", re.DOTALL), 'after'),
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/ai-analysis['\"][^>]*>.*?</a>)", re.DOTALL), 'after'),
    (re.compile(r'([ \t]*<div[^>]*s-divider[^>]*>[ \t]*\n[ \t]*<div[^>]*>Misc<)'), 'before'),
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/upgrade['\"])"), 'before'),
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/settings['\"])"), 'before'),
]

for i, (pattern, mode) in enumerate(anchors):
    m = pattern.search(content)
    if m:
        print(f"  Matched anchor #{i+1} ({mode})", file=sys.stderr)
        if mode == 'after':
            content = content[:m.end()] + NAV_ITEM + content[m.end():]
        else:
            content = content[:m.start()] + NAV_ITEM + '\n' + content[m.start():]
        path.write_text(content, encoding='utf-8')
        sys.exit(0)

print(f"  No anchor matched in {path}", file=sys.stderr)
# Print first 30 navTo calls for debugging
for line in content.splitlines():
    if 'navTo' in line:
        print(f"  navTo: {line.strip()[:120]}", file=sys.stderr)
sys.exit(2)
PYEOF

  code=$?
  if [[ $code -eq 0 ]]; then
    echo -e "${GREEN}UPDATED${NC}  $file"
    ((UPDATED++))
  else
    echo -e "${RED}FAILED${NC}   $file"
    ((FAILED++))
  fi

done < <(find . -name "*.html" \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/wallet-tracker/*" \
  -print0)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Updated :${NC} $UPDATED"
echo -e "  ${YELLOW}Skipped :${NC} $SKIPPED"
echo -e "  ${RED}Failed  :${NC} $FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"