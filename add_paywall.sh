#!/bin/bash
set -e

PAGES="overview indicator signals live-signals ai-analysis journal trenbot autosignals upgrade"

for folder in $PAGES; do
  page="$folder/index.html"

  if [ ! -f "$page" ]; then
    echo "NOT FOUND: $page"
    continue
  fi

  if grep -q '__pw' "$page"; then
    echo "SKIP: $page (already has paywall)"
    continue
  fi

  cp "$page" "$page.bak"

  python3 << PYSCRIPT
import re

paywall = """<script>
(function(){
  var S="https://sjntsmzbiqvtstvofcnx.supabase.co";
  var K="sb_publishable_n0q0FsM9hZARXxKKIDprFw_O6GJfRAg";
  var CK="tren_session";
  var U="https://trenai.vercel.app/checkout-premium";
  function E(){try{var s=JSON.parse(localStorage.getItem(CK)||"null");return s&&s.user&&s.user.email?s.user.email:null}catch(e){return null}}
  async function A(){
    var e=E();if(!e)return false;
    try{var x=JSON.parse(localStorage.getItem("tren_sub")||"null");if(x&&x.status==="active"&&x.plan==="premium")return true;var y=JSON.parse(localStorage.getItem("tren_trenbot_sub")||"null");if(y&&y.status==="active"&&y.plan==="trenbot")return true;var z=JSON.parse(localStorage.getItem("tren_autosignals_sub")||"null");if(z&&z.status==="active"&&z.plan==="auto")return true}catch(e){}
    var P=[["premium","premium"],["trenbot","trenbot"],["auto","auto"]];
    for(var i=0;i<P.length;i++){try{var r=await fetch(S+"/rest/v1/subscribers?email=eq."+encodeURIComponent(e.toLowerCase().trim())+"&plan=eq."+P[i][1]+"&status=eq.active&select=*",{headers:{"apikey":K,"Authorization":"Bearer "+K}});var w=await r.json();if(w&&w.length>0&&w[0].status==="active")return true}catch(e){}}
    return false;
  }
  function W(){
    if(document.getElementById("__pw"))return;
    var d=document.createElement("div");d.id="__pw";
    d.innerHTML='<div style="position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;font-family:Plus Jakarta Sans,sans-serif;"><div style="position:fixed;inset:0;background:rgba(4,8,15,0.75);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);"></div><div style="position:relative;z-index:1;background:linear-gradient(145deg,#0d1628,#080e1a);border:1px solid rgba(255,255,255,0.1);border-radius:20px;padding:48px 40px;text-align:center;max-width:420px;width:90%;box-shadow:0 24px 80px rgba(0,0,0,0.6);"><div style="width:56px;height:56px;border-radius:16px;background:linear-gradient(135deg,#2563eb,#3b82f6);display:flex;align-items:center;justify-content:center;margin:0 auto 20px;font-size:26px;">&#128274;</div><h2 style="font-size:22px;font-weight:800;color:#f0f4ff;margin-bottom:10px;letter-spacing:-0.3px;">Premium Access Required</h2><p style="font-size:14px;color:rgba(240,244,255,0.55);line-height:1.6;margin-bottom:28px;">Start your free trial to unlock this dashboard and all premium features.</p><a href="'+U+'" style="display:inline-block;width:100%;padding:14px 24px;border-radius:12px;background:linear-gradient(90deg,#2563eb,#3b82f6);color:#fff;font-size:14px;font-weight:700;text-decoration:none;transition:opacity 0.2s;font-family:Plus Jakarta Sans,sans-serif;border:none;cursor:pointer;" onmouseover="this.style.opacity=0.9" onmouseout="this.style.opacity=1">Start Your Free Trial &rarr;</a><p style="margin-top:18px;font-size:12px;color:rgba(240,244,255,0.35);">Already have access? <a href="https://trenai.vercel.app/login-page" style="color:#3b82f6;text-decoration:none;font-weight:600;">Sign in</a></p></div></div>';
    document.body.appendChild(d);document.body.style.overflow="hidden";
  }
  (async function(){var h=await A();if(!h)W()})();
})();
</script>"""

with open("$page", "r", encoding="utf-8") as f:
    content = f.read()

new_content = re.sub(
    r'(<body[^>]*>)',
    r'\1\n' + paywall,
    content,
    count=1,
    flags=re.IGNORECASE
)

with open("$page", "w", encoding="utf-8") as f:
    f.write(new_content)

print("OK: $page")
PYSCRIPT

done

echo ""
echo "Done. Paywall injected into all dashboard pages."