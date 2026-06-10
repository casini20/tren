#!/bin/bash
set -e

page="ai-analysis/index.html"

if [ ! -f "$page" ]; then
  echo "NOT FOUND: $page"
  exit 1
fi

python3 << PYSCRIPT
import re

with open("$page", "r", encoding="utf-8") as f:
    content = f.read()

# ── STEP 1: Add IDs to elements that need updating ──

# 1. Add id="trial-card" to the trial card div
content = re.sub(
    r'(<div class="trial-card">)',
    r'<div class="trial-card" id="trial-card">',
    content
)

# 2. Add id="trial-pill" to the top pill (currently says "✦ AI Powered")
content = re.sub(
    r'(<div class="t-pill">)',
    r'<div class="t-pill" id="trial-pill">',
    content
)

# 3. Add id="sidebar-plan-badge" to the sub-status-badge in sidebar
content = re.sub(
    r'(<span class="sub-status-badge trial">)',
    r'<span class="sub-status-badge trial" id="sidebar-plan-badge">',
    content
)

# 4. Add id="s-nm" to user name if missing
if 'id="s-nm"' not in content:
    content = re.sub(
        r'(<div class="u-name">)',
        r'<div class="u-name" id="s-nm">',
        content
    )

# 5. Add id="s-email-display" to email if missing
if 'id="s-email-display"' not in content:
    content = re.sub(
        r'(<div class="u-email">)',
        r'<div class="u-email" id="s-email-display">',
        content
    )

# 6. Add id="s-av" to avatar if missing
if 'id="s-av"' not in content:
    content = re.sub(
        r'(<div class="u-av">)',
        r'<div class="u-av" id="s-av">',
        content
    )

# 7. Add id="prof-menu-name" to profile menu name if missing
if 'id="prof-menu-name"' not in content:
    content = re.sub(
        r'(<div class="prof-menu-name">)',
        r'<div class="prof-menu-name" id="prof-menu-name">',
        content
    )

# 8. Add id="prof-menu-email" to profile menu email if missing
if 'id="prof-menu-email"' not in content:
    content = re.sub(
        r'(<div class="prof-menu-email">)',
        r'<div class="prof-menu-email" id="prof-menu-email">',
        content
    )

# 9. Add id="prof-av-btn" to profile avatar button if missing
if 'id="prof-av-btn"' not in content:
    content = re.sub(
        r'(<div class="prof-av" )',
        r'<div class="prof-av" id="prof-av-btn" ',
        content
    )

# ── STEP 2: Inject subscription detection script ──

sub_script = """<script>
/* ── SUBSCRIPTION DETECTION ─────────────────────────────────────── */
(function(){
  var SUPABASE_AUTH_URL = "https://sjntsmzbiqvtstvofcnx.supabase.co";
  var SUPABASE_AUTH_KEY = "sb_publishable_n0q0FsM9hZARXxKKIDprFw_O6GJfRAg";
  var SESSION_KEY = "tren_session";

  function getSessionEmail(){
    try{ var s = JSON.parse(localStorage.getItem(SESSION_KEY) || "null"); return s && s.user && s.user.email ? s.user.email : null; }catch(e){ return null; }
  }

  async function checkSub(plan){
    var e = getSessionEmail(); if(!e) return false;
    try{
      var r = await fetch(
        SUPABASE_AUTH_URL + "/rest/v1/subscribers?email=eq." + encodeURIComponent(e.toLowerCase().trim()) + "&plan=eq." + plan + "&status=eq.active&select=*",
        { headers: { "apikey": SUPABASE_AUTH_KEY, "Authorization": "Bearer " + SUPABASE_AUTH_KEY } }
      );
      var rows = await r.json();
      return rows && rows.length > 0 && rows[0].status === "active";
    }catch(err){ return false; }
  }

  async function checkAllSubs(){
    var hasP = false, hasTB = false, hasAS = false;
    try{ var x = JSON.parse(localStorage.getItem("tren_sub") || "null"); if(x && x.status === "active" && x.plan === "premium") hasP = true; }catch(e){}
    try{ var y = JSON.parse(localStorage.getItem("tren_trenbot_sub") || "null"); if(y && y.status === "active" && y.plan === "trenbot") hasTB = true; }catch(e){}
    try{ var z = JSON.parse(localStorage.getItem("tren_autosignals_sub") || "null"); if(z && z.status === "active" && z.plan === "auto") hasAS = true; }catch(e){}

    if(!hasP && !hasTB && !hasAS){
      var p = await checkSub("premium");
      var tb = await checkSub("trenbot");
      var as = await checkSub("auto");
      hasP = p; hasTB = tb; hasAS = as;
      if(hasP) localStorage.setItem("tren_sub", JSON.stringify({status:"active",plan:"premium"}));
      if(hasTB) localStorage.setItem("tren_trenbot_sub", JSON.stringify({status:"active",plan:"trenbot"}));
      if(hasAS) localStorage.setItem("tren_autosignals_sub", JSON.stringify({status:"active",plan:"auto"}));
    }

    // Update UI
    var tc = document.getElementById("trial-card");
    var tp = document.getElementById("trial-pill");
    var sb = document.getElementById("sidebar-plan-badge");

    if(hasTB || hasAS || hasP){
      if(tc) tc.style.display = "none";
      var lbl = "⚡ Premium", cls = "premium";
      if(hasTB){ lbl = "⚡ TrenBot"; cls = "automated"; }
      else if(hasAS){ lbl = "⚡ AutoSignals"; cls = "autosignals"; }
      if(tp){ tp.textContent = lbl + " Active"; tp.className = "t-pill " + cls; tp.style.display = "flex"; }
      if(sb){ sb.textContent = lbl; sb.className = "sub-status-badge " + cls; }
    } else {
      if(tc) tc.style.display = "";
      if(tp){ tp.textContent = "⏱ Trial"; tp.className = "t-pill"; tp.style.display = "flex"; }
      if(sb){ sb.textContent = "⏱ Trial"; sb.className = "sub-status-badge trial"; }
    }
  }

  checkAllSubs();
})();
</script>"""

# Remove old sub script if exists
content = re.sub(
    r'<script>\s*/\* ── SUBSCRIPTION DETECTION.*?checkAllSubs\(\);\s*}\)\(\);\s*</script>',
    '',
    content,
    flags=re.DOTALL
)

# Inject after the paywall script (before <div class="shell">)
content = re.sub(
    r'(</script>\s*)(<div class="sidebar-overlay")',
    r'\1\n' + sub_script + r'\n\2',
    content,
    count=1
)

with open("$page", "w", encoding="utf-8") as f:
    f.write(content)

print("OK: $page")
PYSCRIPT