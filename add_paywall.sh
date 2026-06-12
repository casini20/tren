#!/bin/bash
set -e

PAGES="overview indicator signals live-signals ai-analysis journal trenbot autosignals upgrade"

for folder in $PAGES; do
  page="$folder/index.html"

  if [ ! -f "$page" ]; then
    echo "NOT FOUND: $page"
    continue
  fi

  python3 << PYSCRIPT
import re

new_paywall = """<script>
(function(){
  var S="https://sjntsmzbiqvtstvofcnx.supabase.co";
  var K="sb_publishable_n0q0FsM9hZARXxKKIDprFw_O6GJfRAg";
  var CK="tren_session";
  var CHECKOUT_URL="https://trenai.vercel.app/checkout-premium";
  var PRICING_URL="https://trenai.vercel.app/pricing";
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
    var st=document.createElement("style");
    st.id="__pw_st";
    st.textContent="@keyframes pwG{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}@keyframes pwFd{from{opacity:0;transform:translateY(10px) scale(.97)}to{opacity:1;transform:none}}@keyframes pwPl{0%,100%{box-shadow:0 0 0 0 rgba(16,185,129,.5)}70%{box-shadow:0 0 0 8px rgba(16,185,129,0)}}@keyframes pwSh{from{transform:translateX(-250%)}to{transform:translateX(500%)}}#__pw .pw-c{animation:pwFd .35s cubic-bezier(.16,1,.3,1) forwards}#__pw .pw-g{background:linear-gradient(135deg,#1d4ed8,#7c3aed,#06b6d4,#1d4ed8);background-size:300% 300%;animation:pwG 6s ease infinite}#__pw .pw-dot{width:7px;height:7px;border-radius:50%;background:#10b981;animation:pwPl 2s ease infinite;display:inline-block;flex-shrink:0}#__pw .pw-b{display:block;width:100%;padding:15px 24px;border-radius:13px;background:linear-gradient(90deg,#1d4ed8,#3b82f6);color:#fff;font-size:14px;font-weight:700;text-decoration:none;text-align:center;box-sizing:border-box;position:relative;overflow:hidden;transition:transform .15s,box-shadow .15s}#__pw .pw-b:hover{transform:translateY(-2px);box-shadow:0 14px 40px rgba(59,130,246,.45)}#__pw .pw-b::after{content:'';position:absolute;top:0;left:0;width:30%;height:100%;background:linear-gradient(90deg,transparent,rgba(255,255,255,.15),transparent);transform:translateX(-250%);animation:pwSh 3.5s ease 2s infinite}#__pw .pw-f{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07);border-radius:14px;padding:16px 10px;text-align:center;transition:border-color .2s,background .2s}#__pw .pw-f:hover{background:rgba(37,99,235,.08);border-color:rgba(37,99,235,.3)}";
    document.head.appendChild(st);
    var d=document.createElement("div");
    d.id="__pw";
    d.innerHTML='<div style="position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;font-family:Plus Jakarta Sans,sans-serif;padding:20px;box-sizing:border-box;"><div style="position:fixed;inset:0;background:rgba(2,6,14,.92);backdrop-filter:blur(32px);-webkit-backdrop-filter:blur(32px);"></div><div class="pw-c" style="position:relative;z-index:1;width:100%;max-width:476px;"><div class="pw-g" style="position:absolute;inset:-1.5px;border-radius:26px;opacity:.75;"></div><div style="position:relative;background:#060D1A;border-radius:24px;padding:40px 36px 32px;overflow:hidden;"><div style="position:absolute;inset:0;background-image:linear-gradient(rgba(37,99,235,.05) 1px,transparent 1px),linear-gradient(90deg,rgba(37,99,235,.05) 1px,transparent 1px);background-size:32px 32px;pointer-events:none;"></div><div style="position:relative;display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:22px;"><div class="pw-dot"></div><span style="font-size:10.5px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:#3b82f6;">Tren Premium</span></div><h2 style="position:relative;font-size:26px;font-weight:800;color:#f0f4ff;margin:0 0 10px;letter-spacing:-.5px;line-height:1.25;text-align:center;">Your edge is locked.<br><span style="background:linear-gradient(90deg,#60a5fa,#818cf8);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;">Unlock it today.</span></h2><p style="position:relative;font-size:13px;color:rgba(240,244,255,.45);line-height:1.65;text-align:center;margin:0 0 24px;">Real-time NQ signals, AI analysis, and automated bots &mdash; built for serious futures traders.</p><div style="position:relative;display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-bottom:20px;"><div class="pw-f"><div style="font-size:20px;margin-bottom:6px;">&#128225;</div><div style="font-size:11px;font-weight:700;color:#f0f4ff;margin-bottom:3px;">Live Signals</div><div style="font-size:10px;color:rgba(240,244,255,.38);line-height:1.4;">Real-time NQ alerts</div></div><div class="pw-f"><div style="font-size:20px;margin-bottom:6px;">&#129302;</div><div style="font-size:11px;font-weight:700;color:#f0f4ff;margin-bottom:3px;">AI Analysis</div><div style="font-size:10px;color:rgba(240,244,255,.38);line-height:1.4;">Daily market edge</div></div><div class="pw-f"><div style="font-size:20px;margin-bottom:6px;">&#9889;</div><div style="font-size:11px;font-weight:700;color:#f0f4ff;margin-bottom:3px;">Auto Trading</div><div style="font-size:10px;color:rgba(240,244,255,.38);line-height:1.4;">Set-and-forget bots</div></div></div><div style="position:relative;margin-bottom:24px;"><div style="display:flex;flex-direction:column;gap:6px;filter:blur(3.5px);pointer-events:none;user-select:none;"><div style="background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-radius:10px;padding:10px 14px;display:flex;align-items:center;gap:10px;"><span style="width:6px;height:6px;border-radius:50%;background:#10b981;flex-shrink:0;"></span><span style="font-size:11px;font-weight:700;color:#10b981;">LONG</span><span style="font-size:11px;color:rgba(240,244,255,.6);">NQ Future @ 21,847.50</span><span style="margin-left:auto;font-size:11px;font-weight:700;color:#10b981;">+12.5 pts</span></div><div style="background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-radius:10px;padding:10px 14px;display:flex;align-items:center;gap:10px;"><span style="width:6px;height:6px;border-radius:50%;background:#ef4444;flex-shrink:0;"></span><span style="font-size:11px;font-weight:700;color:#ef4444;">SHORT</span><span style="font-size:11px;color:rgba(240,244,255,.6);">NQ Future @ 21,903.00</span><span style="margin-left:auto;font-size:11px;font-weight:700;color:#10b981;">+8.0 pts</span></div></div><div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;border-radius:10px;background:rgba(4,8,16,.3);"><div style="display:flex;align-items:center;gap:8px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:100px;padding:8px 16px;"><svg width="12" height="14" viewBox="0 0 24 24" fill="none" stroke="rgba(240,244,255,.55)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg><span style="font-size:11.5px;font-weight:600;color:rgba(240,244,255,.55);">Signals locked</span></div></div></div><a href="'+CHECKOUT_URL+'" class="pw-b">Start Free Trial &#8594;</a><div style="display:flex;align-items:center;justify-content:center;gap:14px;margin-top:14px;"><a href="'+PRICING_URL+'" style="font-size:12px;color:#3b82f6;text-decoration:none;font-weight:600;">View all plans</a><span style="color:rgba(240,244,255,.15);">&#183;</span><a href="https://trenai.vercel.app/login-page" style="font-size:12px;color:rgba(240,244,255,.3);text-decoration:none;">Sign in</a></div></div></div></div>';
    document.body.appendChild(d);document.body.style.overflow="hidden";
  }
  (async function(){var h=await A();if(!h)W()})();
})();
</script>"""

with open("$page", "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(
    r'<script>\s*\(function\(\)\{.*?__pw.*?\}\)\(\);\s*</script>',
    '',
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'<div id="__pw".*?</div>',
    '',
    content,
    flags=re.DOTALL
)

new_content = re.sub(
    r'(<body[^>]*>)',
    lambda m: m.group(1) + '\n' + new_paywall,
    content,
    count=1,
    flags=re.IGNORECASE
)

with open("$page", "w", encoding="utf-8") as f:
    f.write(new_content)

print("UPDATED: $page")
PYSCRIPT

done

echo ""
echo "Done. All paywalls replaced with new design."
