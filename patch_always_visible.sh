#!/usr/bin/env bash
# =========================================================
# patch_always_visible.sh
#
# 1. Removes ALL login gating from the chat widget on every
#    page — the bubble always shows and the panel is always
#    usable, regardless of session state.
# 2. Removes the sidebar nav item from every page (in case
#    it got re-added, e.g. on overview).
#
# USAGE:
#   ./patch_always_visible.sh .
# =========================================================

set -euo pipefail

PAGES=(
  "overview"
  "ai-analysis"
  "journal"
  "live-signals"
  "signals"
  "upgrade"
)

ROOT_DIR="${1:-.}"

for page in "${PAGES[@]}"; do
  file="$ROOT_DIR/$page/index.html"
  if [[ ! -f "$file" ]]; then
    echo "✘ not found: $file"
    continue
  fi

  python3 - "$file" <<'PYEOF'
import re, sys

file_path = sys.argv[1]
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

changed = False

# ---- 1. Remove login gating in init() ----
old_init = '''  async function init(){
    const { data: { session } } = await gcClient.auth.getSession();

    if (!session){
      fab.style.display = 'none';
      return;
    }

    currentUser = session.user;
    inputRow.style.display = 'flex';
    await loadHistory();
    subscribeRealtime();

    gcClient.auth.onAuthStateChange((_event, newSession) => {
      currentUser = newSession ? newSession.user : null;
      if (!currentUser){
        fab.style.display = 'none';
        panel.classList.remove('open');
        if (gcChannel) gcClient.removeChannel(gcChannel);
      }
    });'''

new_init = '''  async function init(){
    const { data: { session } } = await gcClient.auth.getSession();
    currentUser = session ? session.user : null;

    inputRow.style.display = 'flex';
    await loadHistory();
    subscribeRealtime();

    gcClient.auth.onAuthStateChange((_event, newSession) => {
      currentUser = newSession ? newSession.user : null;
    });'''

if old_init in content:
    content = content.replace(old_init, new_init)
    changed = True
    print(f"  - removed login gating")
else:
    print(f"  - init() gating pattern not found (may already be patched)")

# ---- 2. Remove sidebar nav item, if present ----
nav_pattern = re.compile(
    r'\s*<!-- GC_NAV_MARKER -->.*?</a>\s*\n?',
    re.DOTALL
)
content, n = nav_pattern.subn("", content)
if n:
    changed = True
    print(f"  - removed nav item ({n}x)")

if changed:
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✔ patched: {file_path}")
else:
    print(f"⏭ no changes needed: {file_path}")
PYEOF
done