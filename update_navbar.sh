#!/bin/bash

# update_navbar.sh
# Updates the Affiliate nav link and injects the "Earn 10%" badge CSS across all HTML files.
# Run from your project root: bash update_navbar.sh

set -e

HTML_FILES=$(find . -name "*.html" -not -path "*/node_modules/*" -not -path "*/.git/*")

if [ -z "$HTML_FILES" ]; then
  echo "No HTML files found."
  exit 1
fi

echo "Found HTML files:"
echo "$HTML_FILES"
echo ""

UPDATED=0
SKIPPED=0

for file in $HTML_FILES; do

  # ── 1. Inject CSS if not already present ────────────────────────────────────
  if ! grep -q "nav-affiliate-wrap" "$file"; then

    CSS_BLOCK='.nav-affiliate-wrap { position: relative; display: inline-block; }\n.nav-earn-badge { position: absolute; top: -9px; right: -28px; font-size: 8px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase; color: #34d399; background: rgba(16,185,129,0.08); border: 1px solid rgba(16,185,129,0.35); border-radius: 4px; padding: 2px 6px; line-height: 1.5; transform: rotate(12deg); pointer-events: none; white-space: nowrap; }'

    # Insert CSS just before the closing </style> tag
    if grep -q "</style>" "$file"; then
      sed -i "s|</style>|${CSS_BLOCK}\n</style>|" "$file"
      echo "  [CSS]  Injected badge styles → $file"
    else
      echo "  [WARN] No </style> tag found in $file — CSS not injected"
    fi

  else
    echo "  [SKIP] CSS already present → $file"
  fi

  # ── 2. Update desktop nav: plain Affiliate link → badge version ─────────────
  if grep -q 'href="https://trenai.vercel.app/affiliate"' "$file"; then

    # Only patch links that don't already have the badge
    if ! grep -q "nav-earn-badge" "$file"; then
      sed -i 's|<a href="https://trenai.vercel.app/affiliate">Affiliate</a>|<a href="https://trenai.vercel.app/affiliate" class="nav-affiliate-wrap"><span class="nav-earn-badge">Earn 10%</span>Affiliate</a>|g' "$file"
      echo "  [NAV]  Updated Affiliate link → $file"
      UPDATED=$((UPDATED + 1))
    else
      echo "  [SKIP] Badge already in nav → $file"
      SKIPPED=$((SKIPPED + 1))
    fi

  else
    echo "  [SKIP] No Affiliate link found → $file"
    SKIPPED=$((SKIPPED + 1))
  fi

  echo ""

done

echo "────────────────────────────────"
echo "Done. Updated: $UPDATED  Skipped: $SKIPPED"