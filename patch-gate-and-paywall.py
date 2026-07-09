#!/usr/bin/env python3
import os, sys

# ── PATCH DEFINITIONS ────────────────────────────────────────────────────────

PATCHES = [
    # 1. Login-gate: redirect unauthenticated users before showing paywall
    {
        "desc": "Login-gate redirect",
        "old":  "(async function(){var h=await A();if(!h)W()})();",
        "new":  "(async function(){var e=E();if(!e){window.location.href='https://trenai.vercel.app/login-page';return;}var h=await A();if(!h)W()})();"
    },
    # 2. Backdrop: very see-through, heavy blur
    {
        "desc": "Backdrop opacity",
        "old":  "background:rgba(2,6,14,.92);backdrop-filter:blur(32px)",
        "new":  "background:rgba(2,6,14,.35);backdrop-filter:blur(52px)"
    },
    # Also catch already-partially-patched files from the previous script
    {
        "desc": "Backdrop opacity (prev patch)",
        "old":  "background:rgba(2,6,14,.55);backdrop-filter:blur(48px)",
        "new":  "background:rgba(2,6,14,.35);backdrop-filter:blur(52px)"
    },
    # 3. Card body: glassier
    {
        "desc": "Card glass bg",
        "old":  "background:#060D1A;border-radius:24px",
        "new":  "background:rgba(6,13,26,.75);border-radius:24px"
    },
    # Catch already-patched card bg too
    {
        "desc": "Card glass bg (prev patch)",
        "old":  "background:rgba(6,13,26,.82);border-radius:24px",
        "new":  "background:rgba(6,13,26,.75);border-radius:24px"
    },
    # 4. Gradient border: pop it more against lighter bg
    {
        "desc": "Gradient border opacity",
        "old":  "position:absolute;inset:-1.5px;border-radius:26px;opacity:.75",
        "new":  "position:absolute;inset:-1.5px;border-radius:26px;opacity:.95"
    },
    {
        "desc": "Gradient border opacity (prev patch)",
        "old":  "position:absolute;inset:-1.5px;border-radius:26px;opacity:.9",
        "new":  "position:absolute;inset:-1.5px;border-radius:26px;opacity:.95"
    },
]

# ── MAIN ─────────────────────────────────────────────────────────────────────

def patch_file(path):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        original = f.read()

    content = original
    applied = []

    for p in PATCHES:
        if p["old"] in content:
            content = content.replace(p["old"], p["new"])
            applied.append(p["desc"])

    if content != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        return applied
    return []

found = updated = 0
for root, dirs, files in os.walk("."):
    dirs[:] = [d for d in dirs if d not in ("node_modules", ".git")]
    for name in files:
        if name != "index.html":
            continue
        path = os.path.join(root, name)
        found += 1
        patches = patch_file(path)
        if patches:
            updated += 1
            print(f"  ✅ {path}")
            for p in patches:
                print(f"       → {p}")
        else:
            print(f"  ⏭️  {path} (no changes)")

print(f"\nDone. {updated}/{found} files updated.")