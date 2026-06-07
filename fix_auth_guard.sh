#!/bin/bash

python3 - <<'PYEOF'
import os

guard = """<script>
  if (!sessionStorage.getItem('tren_session')) {
    window.location.replace('/login-page');
  }
</script>"""

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ('node_modules', '.git')]
    for fname in files:
        if fname != 'overview.html':
            continue
        path = os.path.join(root, fname)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        if 'tren_session' in content:
            print(f"  — Already guarded: {path}")
            continue
        injected = content.replace('<body>', '<body>\n' + guard, 1)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(injected)
        print(f"  ✓ Auth guard injected: {path}")

PYEOF
