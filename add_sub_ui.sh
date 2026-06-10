#!/bin/bash
set -e

page="ai-analysis/index.html"

if [ ! -f "$page" ]; then
  echo "NOT FOUND: $page"
  exit 1
fi

python3 << PYSCRIPT
import re

# The subscription detection + UI update script to inject
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
    var tp = document.querySelector(".t-pill");
    var sb = document.querySelector(".sub-status-badge");

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

with open("$page", "r", encoding="utf-8") as f:
    content = f.read()

# Check if already injected
if '__sub_ui' in content:
    print("SKIP: already has subscription UI script")
    exit(0)

# Inject right after the paywall script (before <div class="shell">)
# Find the paywall closing </script> followed by <div class="shell">
new_content = re.sub(
    r'(</script>\s*)(<div class="shell">)',
    r'\1' + sub_script + r'\n\2',
    content,
    count=1
)

with open("$page", "w", encoding="utf-8") as f:
    f.write(new_content)

print("OK: $page")
PYSCRIPT