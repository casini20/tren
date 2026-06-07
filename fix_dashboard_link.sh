#!/bin/bash

python3 - <<'PYEOF'
import os, re

script = """<script>
  function goToDashboard(e) {
    e.preventDefault();
    if (sessionStorage.getItem('tren_session')) {
      window.location.href = '/overview';
    } else {
      window.location.href = '/login-page';
    }
  }
</script>"""

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ('node_modules', '.git')]
    for fname in files:
        if not fname.endswith('.html'):
            continue
        path = os.path.join(root, fname)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Skip non-homepage files that already have session logic
        if 'goToDashboard' in content:
            print(f"  — Already fixed: {path}")
            continue

        # Only touch files that link to /overview or /dashboard
        if '/overview' not in content and '/dashboard' not in content:
            continue

        # Inject the script before </body>
        if '</body>' not in content:
            continue

        updated = re.sub(
            r'href=["\'](?:https://trenai\.vercel\.app)?/(?:overview|dashboard)["\']',
            'href="#" onclick="goToDashboard(event)"',
            content
        )

        if updated == content:
            print(f"  — No dashboard links found: {path}")
            continue

        updated = updated.replace('</body>', script + '\n</body>')

        with open(path, 'w', encoding='utf-8') as f:
            f.write(updated)
        print(f"  ✓ Fixed: {path}")

PYEOF
