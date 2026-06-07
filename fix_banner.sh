#!/bin/bash

python3 - <<'PYEOF'
import os, re, sys

banner = r'<div style="position:fixed;top:0;left:0;right:0;z-index:9999;background:var\(--bg3\);border-bottom:1px solid var\(--border\);padding:1rem;text-align:center;font-size:14px;color:var\(--ts\);">\s*</div>\s*'
spacer = r'<div style="height:60px;"></div>\s*'

fixed, skipped = 0, 0

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d != 'node_modules']
    for fname in files:
        if not fname.endswith('.html'):
            continue
        path = os.path.join(root, fname)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        cleaned = re.sub(banner, '', content)
        cleaned = re.sub(spacer, '', cleaned)
        if cleaned != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            print(f"  ✓ Fixed:   {path}")
            fixed += 1
        else:
            print(f"  — Skipped: {path}")
            skipped += 1

print(f"\nDone. {fixed} file(s) fixed, {skipped} skipped.")
PYEOF
