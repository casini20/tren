#!/usr/bin/env python3
"""
inject_wallet_nav.py
Run from the root of your tren repo:
  python3 inject_wallet_nav.py
"""
import pathlib, re, sys

NAV_ITEM = """
      <a class="s-item" onclick="navTo('https://trenai.vercel.app/wallet-tracker')">
        <span class="s-ic">&#x1F45B;</span><span>Wallet Tracker</span>
        <span style="margin-left:auto;font-size:9px;font-weight:700;padding:2px 6px;border-radius:4px;background:rgba(37,99,235,.18);border:0.5px solid rgba(37,99,235,.35);color:var(--al);">NEW</span>
      </a>"""

# Pages that should NOT get the nav item
SKIP_DIRS = {
    'wallet-tracker', 'node_modules', '.git',
    'checkout-autosignals', 'checkout-indicator',
    'checkout-premium', 'checkout-trenbot',
    'login-page', 'thank-you-indicator',
    'affiliate-terms', 'privacy-policy', 'terms-conditions',
    'contact', 'pricing',
}

ANCHORS = [
    # after indicator
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/indicator['\"][^>]*>.*?</a>)", re.DOTALL), 'after'),
    # after autosignals
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/autosignals['\"][^>]*>.*?</a>)", re.DOTALL), 'after'),
    # after trenbot
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/trenbot['\"][^>]*>.*?</a>)", re.DOTALL), 'after'),
    # after ai-analysis
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/ai-analysis['\"][^>]*>.*?</a>)", re.DOTALL), 'after'),
    # before upgrade
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/upgrade['\"])"), 'before'),
    # before settings
    (re.compile(r"(<a[^>]*navTo\(['\"]https://trenai\.vercel\.app/settings['\"])"), 'before'),
]

root = pathlib.Path('.')
updated, skipped, failed = [], [], []

for html in sorted(root.rglob('*.html')):
    parts = set(html.parts)
    # skip excluded dirs
    if parts & SKIP_DIRS:
        continue
    # skip snippet files
    if html.name.startswith('_'):
        continue

    content = html.read_text(encoding='utf-8')

    # skip if already has it
    if 'wallet-tracker' in content:
        skipped.append(str(html))
        print(f'SKIP (done)   {html}')
        continue

    # skip if no navTo (not a dashboard page)
    if 'navTo' not in content:
        skipped.append(str(html))
        print(f'SKIP (no nav) {html}')
        continue

    matched = False
    for pattern, mode in ANCHORS:
        m = pattern.search(content)
        if m:
            if mode == 'after':
                content = content[:m.end()] + NAV_ITEM + content[m.end():]
            else:
                content = content[:m.start()] + NAV_ITEM + '\n' + content[m.start():]
            html.write_text(content, encoding='utf-8')
            updated.append(str(html))
            print(f'UPDATED       {html}')
            matched = True
            break

    if not matched:
        failed.append(str(html))
        print(f'FAILED        {html}')

print()
print('━' * 44)
print(f'  Updated : {len(updated)}')
print(f'  Skipped : {len(skipped)}')
print(f'  Failed  : {len(failed)}')
print('━' * 44)
if failed:
    print('\nFailed files (manual fix needed):')
    for f in failed: print(' ', f)