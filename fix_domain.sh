#!/bin/bash

python3 - <<'PYEOF'
import os

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ('node_modules', '.git')]
    for fname in files:
        if not fname.endswith(('.html', '.js', '.ts', '.jsx', '.tsx')):
            continue
        path = os.path.join(root, fname)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        cleaned = content.replace('tren.framer.ai', 'trenai.vercel.app')
        if cleaned != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            print(f"  ✓ Fixed: {path}")
        else:
            print(f"  — Skipped: {path}")

PYEOF
