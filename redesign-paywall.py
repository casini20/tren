#!/usr/bin/env python3
import os, re

# ── The exact old innerHTML value as it appears in the JS string ──────────────
OLD = """d.innerHTML='<div style="position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;font-family:Plus Jakarta Sans,sans-serif;padding:20px;box-sizing:border-box;"><div style="position:fixed;inset:0;background:rgba(2,6,14,.92);backdrop-filter:blur(32px);-webkit-backdrop-filter:blur(32px);"></div><div class="pw-c" style="position:relative;z-index:1;width:100%;max-width:476px;"><div class="pw-g" style="position:absolute;inset:-1.5px;border-radius:26px;opacity:.75;"></div><div style="position:relative;background:#060D1A;border-radius:24px;padding:40px 36px 32px;overflow:hidden;"><div style="position:absolute;inset:0;background-image:linear-gradient(rgba(37,99,235,.05) 1px,transparent 1px),linear-gradient(90deg,rgba(37,99,235,.05) 1px,transparent 1px);background-size:32px 32px;pointer-events:none;"></div><div style="position:relative;display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:22px;"><div class="pw-dot"></div><span style="font-size:10.5px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:#3b82f6;">Tren Premium</span></div><h2 style="position:relative;font-size:26px;font-weight:800;color:#f0f4ff;margin:0 0 10px;letter-spacing:-.5px;line-height:1.25;text-align:center;">Your edge is locked.<br><span style="background:linear-gradient(90deg,#60a5fa,#818cf8);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;">Unlock it today.</span></h2><p style="position:relative;font-size:13px;color:rgba(240,244,255,.45);line-height:1.65;text-align:center;margin:0 0 24px;">Real-time NQ signals, AI analysis, and automated bots &mdash; built for serious futures traders.</p><div style="position:relative;display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-bottom:20px;"><div class="pw-f"><div style="font-size:20px;margin-bottom:6px;">&#128225;</div><div style="font-size:11px;font-weight:700;color:#f0f4ff;margin-bottom:3px;">Live Signals</div><div style="font-size:10px;color:rgba(240,244,255,.38);line-height:1.4;">Real-time NQ alerts</div></div><div class="pw-f"><div style="font-size:20px;margin-bottom:6px;">&#129302;</div><div style="font-size:11px;font-weight:700;color:#f0f4ff;margin-bottom:3px;">AI Analysis</div><div style="font-size:10px;color:rgba(240,244,255,.38);line-height:1.4;">Daily market edge</div></div><div class="pw-f"><div style="font-size:20px;margin-bottom:6px;">&#9889;</div><div style="font-size:11px;font-weight:700;color:#f0f4ff;margin-bottom:3px;">Auto Trading</div><div style="font-size:10px;color:rgba(240,244,255,.38);line-height:1.4;">Set-and-forget bots</div></div></div><div style="position:relative;margin-bottom:24px;"><div style="display:flex;flex-direction:column;gap:6px;filter:blur(3.5px);pointer-events:none;user-select:none;"><div style="background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-radius:10px;padding:10px 14px;display:flex;align-items:center;gap:10px;"><span style="width:6px;height:6px;border-radius:50%;background:#10b981;flex-shrink:0;"></span><span style="font-size:11px;font-weight:700;color:#10b981;">LONG</span><span style="font-size:11px;color:rgba(240,244,255,.6);">NQ Future @ 21,847.50</span><span style="margin-left:auto;font-size:11px;font-weight:700;color:#10b981;">+12.5 pts</span></div><div style="background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-radius:10px;padding:10px 14px;display:flex;align-items:center;gap:10px;"><span style="width:6px;height:6px;border-radius:50%;background:#ef4444;flex-shrink:0;"></span><span style="font-size:11px;font-weight:700;color:#ef4444;">SHORT</span><span style="font-size:11px;color:rgba(240,244,255,.6);">NQ Future @ 21,903.00</span><span style="margin-left:auto;font-size:11px;font-weight:700;color:#10b981;">+8.0 pts</span></div></div><div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;border-radius:10px;background:rgba(4,8,16,.3);"><div style="display:flex;align-items:center;gap:8px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:100px;padding:8px 16px;"><svg width="12" height="14" viewBox="0 0 24 24" fill="none" stroke="rgba(240,244,255,.55)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg><span style="font-size:11.5px;font-weight:600;color:rgba(240,244,255,.55);">Signals locked</span></div></div></div><a href=\\'+CHECKOUT_URL+\\'  class="pw-b">Start Free Trial &#8594;</a><div style="display:flex;align-items:center;justify-content:center;gap:14px;margin-top:14px;"><a href=\\'+PRICING_URL+\\' style="font-size:12px;color:#3b82f6;text-decoration:none;font-weight:600;">View all plans</a><span style="color:rgba(240,244,255,.15);">&#183;</span><a href="https://trenai.vercel.app/login-page" style="font-size:12px;color:rgba(240,244,255,.3);text-decoration:none;">Sign in</a></div></div></div></div>\\';"""

# ── New design ────────────────────────────────────────────────────────────────
NEW = """d.innerHTML='<div style="position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;font-family:Plus Jakarta Sans,sans-serif;padding:20px;box-sizing:border-box;">'+\
'<div style="position:fixed;inset:0;background:rgba(2,6,14,.22);backdrop-filter:blur(64px);-webkit-backdrop-filter:blur(64px);"></div>'+\
'<div class="pw-c" style="position:relative;z-index:1;width:100%;max-width:460px;">'+\
'<div class="pw-g" style="position:absolute;inset:-1px;border-radius:24px;opacity:.95;"></div>'+\
'<div style="position:relative;background:rgba(5,11,24,.85);border-radius:23px;padding:36px 32px 28px;overflow:hidden;">'+\
'<div style="position:absolute;top:-80px;left:50%;transform:translateX(-50%);width:300px;height:160px;background:radial-gradient(ellipse,rgba(59,130,246,.13) 0%,transparent 70%);pointer-events:none;"></div>'+\
'<div style="position:relative;display:flex;align-items:center;justify-content:center;gap:7px;margin-bottom:18px;">'+\
'<div class="pw-dot"></div>'+\
'<span style="font-size:10px;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:#3b82f6;">Tren Premium</span>'+\
'</div>'+\
'<h2 style="position:relative;font-size:28px;font-weight:800;color:#f0f4ff;margin:0 0 10px;letter-spacing:-.6px;line-height:1.2;text-align:center;">Your edge is locked.<br><span style="background:linear-gradient(90deg,#60a5fa 0%,#818cf8 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;">Unlock it today.</span></h2>'+\
'<p style="position:relative;font-size:12.5px;color:rgba(240,244,255,.38);line-height:1.65;text-align:center;margin:0 0 22px;">Real-time NQ signals, AI analysis &amp; automated bots &mdash; built for serious futures traders.</p>'+\
'<div style="display:flex;justify-content:center;gap:7px;flex-wrap:wrap;margin-bottom:22px;">'+\
'<div style="display:flex;align-items:center;gap:6px;background:rgba(59,130,246,.08);border:1px solid rgba(59,130,246,.18);border-radius:100px;padding:6px 13px;">'+\
'<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="2"/><path d="M12 2v3M12 19v3M4.22 4.22l2.12 2.12M17.66 17.66l2.12 2.12M2 12h3M19 12h3M4.22 19.78l2.12-2.12M17.66 6.34l2.12-2.12"/></svg>'+\
'<span style="font-size:11px;font-weight:600;color:rgba(240,244,255,.72);">Live Signals</span>'+\
'</div>'+\
'<div style="display:flex;align-items:center;gap:6px;background:rgba(129,140,248,.08);border:1px solid rgba(129,140,248,.18);border-radius:100px;padding:6px 13px;">'+\
'<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#818cf8" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a10 10 0 1 0 10 10"/><path d="M12 6v6l4 2"/></svg>'+\
'<span style="font-size:11px;font-weight:600;color:rgba(240,244,255,.72);">AI Analysis</span>'+\
'</div>'+\
'<div style="display:flex;align-items:center;gap:6px;background:rgba(16,185,129,.08);border:1px solid rgba(16,185,129,.18);border-radius:100px;padding:6px 13px;">'+\
'<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>'+\
'<span style="font-size:11px;font-weight:600;color:rgba(240,244,255,.72);">Auto Trading</span>'+\
'</div>'+\
'</div>'+\
'<div style="position:relative;margin-bottom:24px;border-radius:12px;overflow:hidden;">'+\
'<div style="display:flex;flex-direction:column;gap:6px;filter:blur(4px);pointer-events:none;user-select:none;">'+\
'<div style="background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07);border-radius:10px;padding:11px 14px;display:flex;align-items:center;gap:10px;">'+\
'<span style="width:6px;height:6px;border-radius:50%;background:#10b981;flex-shrink:0;display:block;"></span>'+\
'<span style="font-size:11px;font-weight:700;color:#10b981;">LONG</span>'+\
'<span style="font-size:11px;color:rgba(240,244,255,.55);">NQ Future @ 21,847.50</span>'+\
'<span style="margin-left:auto;font-size:11px;font-weight:700;color:#10b981;">+12.5 pts</span>'+\
'</div>'+\
'<div style="background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07);border-radius:10px;padding:11px 14px;display:flex;align-items:center;gap:10px;">'+\
'<span style="width:6px;height:6px;border-radius:50%;background:#ef4444;flex-shrink:0;display:block;"></span>'+\
'<span style="font-size:11px;font-weight:700;color:#ef4444;">SHORT</span>'+\
'<span style="font-size:11px;color:rgba(240,244,255,.55);">NQ Future @ 21,903.00</span>'+\
'<span style="margin-left:auto;font-size:11px;font-weight:700;color:#10b981;">+8.0 pts</span>'+\
'</div>'+\
'</div>'+\
'<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;background:rgba(3,7,18,.15);">'+\
'<div style="display:flex;align-items:center;gap:7px;background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.11);border-radius:100px;padding:7px 16px;backdrop-filter:blur(6px);">'+\
'<svg width="11" height="13" viewBox="0 0 24 24" fill="none" stroke="rgba(240,244,255,.5)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>'+\
'<span style="font-size:11px;font-weight:600;color:rgba(240,244,255,.5);">Signals locked</span>'+\
'</div>'+\
'</div>'+\
'</div>'+\
'<a href=\\'+CHECKOUT_URL+\\' class="pw-b">Start Free Trial &#8594;</a>'+\
'<div style="display:flex;align-items:center;justify-content:center;gap:16px;margin-top:14px;">'+\
'<a href=\\'+PRICING_URL+\\' style="font-size:12px;color:#3b82f6;text-decoration:none;font-weight:600;">View all plans</a>'+\
'<span style="color:rgba(240,244,255,.12);">&#183;</span>'+\
'<a href="https://trenai.vercel.app/login-page" style="font-size:12px;color:rgba(240,244,255,.4);text-decoration:none;font-weight:500;">Sign in</a>'+\
'</div>'+\
'</div>'+\
'</div>'+\
'</div>\\';"""

# ── Also patch the login-gate IIFE if not done yet ────────────────────────────
GATE_OLD = "(async function(){var h=await A();if(!h)W()})();"
GATE_NEW = "(async function(){var e=E();if(!e){window.location.href='https://trenai.vercel.app/login-page';return;}var h=await A();if(!h)W()})();"

# ── Walk and patch ────────────────────────────────────────────────────────────
found = updated = 0
for root, dirs, files in os.walk("."):
    dirs[:] = [d for d in dirs if d not in ("node_modules", ".git")]
    for name in files:
        if name != "index.html":
            continue
        path = os.path.join(root, name)
        found += 1
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()

        original = content
        applied = []

        if OLD in content:
            content = content.replace(OLD, NEW)
            applied.append("Paywall redesign")

        if GATE_OLD in content:
            content = content.replace(GATE_OLD, GATE_NEW)
            applied.append("Login-gate redirect")

        if content != original:
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            updated += 1
            print(f"  ✅ {path}")
            for a in applied:
                print(f"       → {a}")
        else:
            print(f"  ⏭️  {path} (no match)")

print(f"\nDone. {updated}/{found} files updated.")