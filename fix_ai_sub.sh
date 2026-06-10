#!/bin/bash
set -e

page="ai-analysis/index.html"

if [ ! -f "$page" ]; then
  echo "NOT FOUND: $page"
  exit 1
fi

python3 << 'PYEOF'
import re

with open("ai-analysis/index.html", "r", encoding="utf-8") as f:
    content = f.read()

# STEP 1: Add session recovery
session_recovery = """<script>
(function(){
  try{
    var p = new URLSearchParams(window.location.search);
    var t = p.get('_t');
    if(t){
      var existing = localStorage.getItem('tren_session');
      if(!existing){
        var decoded = JSON.parse(atob(decodeURIComponent(t)));
        localStorage.setItem('tren_session', JSON.stringify(decoded));
      }
      window.history.replaceState({}, '', window.location.pathname);
    }
  }catch(e){}
})();
</script>"""

if 'SESSION RECOVERY' not in content:
    body_idx = content.find('<body>')
    if body_idx != -1:
        insert_pos = body_idx + len('<body>')
        content = content[:insert_pos] + '\n' + session_recovery + content[insert_pos:]

# STEP 2: Fix element IDs using string replace (no regex)
content = content.replace('<div class="trial-card">', '<div class="trial-card" id="trial-card">', 1)
content = content.replace('<div class="t-pill">&#9996; AI Powered</div>', '<div class="t-pill" id="trial-pill">&#9201; <span id="pill-days">7</span> days left in trial</div>')
content = content.replace('<div class="t-pill">&#10022; AI Powered</div>', '<div class="t-pill" id="trial-pill">&#9201; <span id="pill-days">7</span> days left in trial</div>')
content = content.replace('<div class="t-pill">\u2726 AI Powered</div>', '<div class="t-pill" id="trial-pill">\u23f1 <span id="pill-days">7</span> days left in trial</div>')
content = content.replace('<span class="sub-status-badge trial">\u23f1 Trial</span>', '<span class="sub-status-badge trial" id="sidebar-plan-badge">\u23f1 Trial</span>')
content = content.replace('<div class="u-name">Trader</div>', '<div class="u-name" id="s-nm">Trader</div>')
content = content.replace('<div class="u-email">\u2014</div>', '<div class="u-email" id="s-email-display">\u2014</div>')
content = content.replace('<div class="u-av">T</div>', '<div class="u-av" id="s-av">T</div>')
content = content.replace('<div class="prof-menu-name">Trader</div>', '<div class="prof-menu-name" id="prof-menu-name">Trader</div>')
content = content.replace('<div class="prof-menu-email">\u2014</div>', '<div class="prof-menu-email" id="prof-menu-email">\u2014</div>')
content = content.replace('<div class="prof-av" onclick="toggleProfileMenu()">T</div>', '<div class="prof-av" id="prof-av-btn" onclick="toggleProfileMenu()">T</div>')

# STEP 3: Remove old sub scripts
for marker in ['SUBSCRIPTION DETECTION', 'SUBSCRIPTION & USER INFO']:
    idx = content.find(marker)
    while idx != -1:
        script_start = content.rfind('<script>', 0, idx)
        script_end = content.find('</script>', idx)
        if script_start != -1 and script_end != -1:
            content = content[:script_start] + content[script_end + len('</script>'):]
        idx = content.find(marker)

# STEP 4: Build sub script WITHOUT backslash-w in replacement context
# The issue is that when we use re.sub, \\w in replacement becomes \w which is invalid
# We'll use string.replace() instead

sub_script = """<script>
(function(){
  var SUPABASE_AUTH_URL = "https://sjntsmzbiqvtstvofcnx.supabase.co";
  var SUPABASE_AUTH_KEY = "sb_publishable_n0q0FsM9hZARXxKKIDprFw_O6GJfRAg";
  var SESSION_KEY = "tren_session";

  var _session = null;
  try{ _session = JSON.parse(localStorage.getItem(SESSION_KEY) || "null"); }catch(e){}

  function getSessionEmail(){
    return (_session && _session.user && _session.user.email) ? _session.user.email : "\u2014";
  }
  function getSessionFullName(){
    if(_session && _session.user){
      var m = _session.user.user_metadata || {};
      if(m.full_name) return m.full_name;
      if(m.name) return m.name;
      if(_session.user.email){
        var parts = _session.user.email.split("@")[0];
        return parts.replace(/[._]/g, " ").replace(/\\b\\w/g, function(c){ return c.toUpperCase(); });
      }
    }
    return "Trader";
  }
  function getUserDisplayName(){
    try{
      var prefs = JSON.parse(localStorage.getItem("tren_prefs") || "{}");
      var names = prefs.display_names || {};
      return names[getSessionEmail()] || getSessionFullName();
    }catch(e){ return getSessionFullName(); }
  }

  var name = getUserDisplayName(), email = getSessionEmail(), init = name.charAt(0).toUpperCase();
  var sNm = document.getElementById("s-nm"); if(sNm) sNm.textContent = name;
  var pMn = document.getElementById("prof-menu-name"); if(pMn) pMn.textContent = name;
  var sAv = document.getElementById("s-av"); if(sAv) sAv.textContent = init;
  var pAv = document.getElementById("prof-av-btn"); if(pAv) pAv.textContent = init;
  var sEm = document.getElementById("s-email-display"); if(sEm) sEm.textContent = email;
  var pEm = document.getElementById("prof-menu-email"); if(pEm) pEm.textContent = email;

  var _subData = null, _autoSubData = null, _autoSignalsSubData = null;
  try{ _subData = JSON.parse(localStorage.getItem("tren_sub") || "null"); }catch(e){}
  try{ _autoSubData = JSON.parse(localStorage.getItem("tren_trenbot_sub") || "null"); }catch(e){}
  try{ _autoSignalsSubData = JSON.parse(localStorage.getItem("tren_autosignals_sub") || "null"); }catch(e){}

  async function checkSub(plan){
    var e = getSessionEmail(); if(!e || e === "\u2014") return false;
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

    if(_subData && _subData.status === "active" && _subData.plan === "premium") hasP = true;
    if(_autoSubData && _autoSubData.status === "active" && _autoSubData.plan === "trenbot") hasTB = true;
    if(_autoSignalsSubData && _autoSignalsSubData.status === "active" && _autoSignalsSubData.plan === "auto") hasAS = true;

    if(!hasP && !hasTB && !hasAS){
      var p = await checkSub("premium");
      var tb = await checkSub("trenbot");
      var as = await checkSub("auto");
      hasP = p; hasTB = tb; hasAS = as;
      if(hasP) localStorage.setItem("tren_sub", JSON.stringify({status:"active",plan:"premium"}));
      if(hasTB) localStorage.setItem("tren_trenbot_sub", JSON.stringify({status:"active",plan:"trenbot"}));
      if(hasAS) localStorage.setItem("tren_autosignals_sub", JSON.stringify({status:"active",plan:"auto"}));
    }

    var tc = document.getElementById("trial-card");
    var tp = document.getElementById("trial-pill");
    var sb = document.getElementById("sidebar-plan-badge");

    if(hasTB || hasAS || hasP){
      if(tc) tc.style.display = "none";
      var lbl = "\u26a1 Premium", cls = "premium";
      if(hasTB){ lbl = "\u26a1 TrenBot"; cls = "automated"; }
      else if(hasAS){ lbl = "\u26a1 AutoSignals"; cls = "autosignals"; }
      if(tp){ tp.textContent = lbl + " Active"; tp.className = "t-pill " + cls; }
      if(sb){ sb.textContent = lbl; sb.className = "sub-status-badge " + cls; }
    } else {
      if(tc) tc.style.display = "";
      if(tp){ tp.innerHTML = '\u23f1 <span id="pill-days">7</span> days left in trial'; tp.className = "t-pill"; }
      if(sb){ sb.textContent = "\u23f1 Trial"; sb.className = "sub-status-badge trial"; }
    }
  }

  checkAllSubs();
})();
</script>"""

# Use string.replace() instead of regex for injection
marker = '<div class="sidebar-overlay"'
idx = content.find(marker)
if idx != -1:
    content = content[:idx] + sub_script + '\n' + content[idx:]

with open("ai-analysis/index.html", "w", encoding="utf-8") as f:
    f.write(content)

print("OK: ai-analysis/index.html")
PYEOF