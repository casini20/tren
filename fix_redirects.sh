#!/bin/bash

python3 - <<'PYEOF'
import os, re

pattern = r'((?:href|action|window\.location(?:\.href)?|redirect|replace|assign)\s*[=:]\s*["\'])([^"\']*)/dashboard(["\'\s?#])'

fixed, skipped = 0, 0

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ('node_modules', '.git')]
    for fname in files:
        if not fname.endswith(('.html', '.js', '.ts', '.jsx', '.tsx')):
            continue
        path = os.path.join(root, fname)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        cleaned = re.sub(pattern, lambda m: m.group(1) + m.group(2) + '/overview' + m.group(3), content)
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
