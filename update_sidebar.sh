#!/usr/bin/env bash
# =============================================================
#  update_sidebar.sh
#  Finds every Tren HTML page and replaces the sidebar
#  CSS + HTML with the v3 redesign. Also injects navTo()
#  into any page missing it.
#
#  Usage:
#    chmod +x update_sidebar.sh
#    ./update_sidebar.sh
# =============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

PYWORKER=$(mktemp /tmp/sidebar_worker_XXXX.py)
trap "rm -f $PYWORKER" EXIT

cat > "$PYWORKER" << 'PYEOF'
import sys, re

filepath = sys.argv[1]

with open(filepath, 'r', encoding='utf-8') as fh:
    content = fh.read()

original = content

# ── Detect active page from file path ──
page = 'overview'
path_lower = filepath.lower()
for p in ['live-signals','signals','journal','ai-analysis','trenbot','autosignals','indicator','upgrade','settings']:
    if p in path_lower:
        page = p
        break

def nav_item(label, icon, url, page_key, extra_class='', badge=''):
    active = ' on' if page == page_key else ''
    badge_html = f'\n        <span class="{badge[0]}">{badge[1]}</span>' if badge else ''
    return f'''      <a class="s-item{extra_class}{active}" onclick="navTo('{url}')">
        <span class="s-ic">{icon}</span><span>{label}</span>{badge_html}
      </a>'''

live_icon = '<span class="live-dot-nav"></span>'

nav_html = '\n'.join([
    nav_item('Live Signals',  live_icon,       'https://trenai.vercel.app/live-signals', 'live-signals'),
    nav_item('Overview',      '\U0001f4ca',    'https://trenai.vercel.app/overview',     'overview'),
    nav_item('Recent Trades', '\u26a1',        'https://trenai.vercel.app/signals',      'signals'),
    nav_item('Journal',       '\U0001f4d3',    'https://trenai.vercel.app/journal',      'journal'),
])

tools_html = '\n'.join([
    nav_item('AI Analysis',  '\u2728',         'https://trenai.vercel.app/ai-analysis',  'ai-analysis', ' ai-item', ('s-beta', 'BETA')),
    nav_item('TrenBot',      '\U0001f916',     'https://trenai.vercel.app/trenbot',      'trenbot'),
    nav_item('AutoSignals',  '\u26a1',         'https://trenai.vercel.app/autosignals',  'autosignals'),
    nav_item('Indicator',    '\U0001f4c8',     'https://trenai.vercel.app/indicator',    'indicator'),
])

misc_html = '\n'.join([
    nav_item('Upgrade',  '\U0001f451',         'https://trenai.vercel.app/upgrade',      'upgrade',  ' gold', ('s-badge', 'PRO')),
    nav_item('Settings', '\u2699\ufe0f',       'https://trenai.vercel.app/settings',     'settings'),
])

NEW_CSS = """\
/* \u2500\u2500 SIDEBAR \u2500\u2500 */
.sidebar{width:var(--sw);min-width:var(--sw);height:100vh;border-right:1px solid var(--border);background:#060b14;display:flex;flex-direction:column;padding:0;position:relative;z-index:20;overflow-y:auto;overflow-x:hidden;scrollbar-width:none;}
.sidebar::-webkit-scrollbar{display:none;}
.s-logo{font-size:17px;font-weight:600;padding:22px 18px 18px;display:flex;align-items:center;gap:9px;text-decoration:none;color:inherit;letter-spacing:-0.4px;}
.s-logo-dot{width:8px;height:8px;border-radius:50%;background:var(--accent);box-shadow:0 0 0 3px rgba(37,99,235,0.2);flex-shrink:0;}
.s-logo span{color:var(--al);}
.s-section-label{font-size:9px;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;color:rgba(240,244,255,0.18);padding:12px 18px 4px;}
.s-nav{flex:1;display:flex;flex-direction:column;padding:0 10px;gap:1px;}
.s-item{display:flex;align-items:center;gap:10px;padding:8px 10px;border-radius:8px;font-size:13px;font-weight:500;color:rgba(240,244,255,0.42);cursor:pointer;transition:background .12s,color .12s;text-decoration:none;position:relative;}
.s-item:hover{background:rgba(255,255,255,.04);color:rgba(240,244,255,0.8);}
.s-item.on{background:rgba(37,99,235,.14);color:#e0eaff;}
.s-item.on::before{content:'';position:absolute;left:-6px;top:50%;transform:translateY(-50%);width:3px;height:16px;border-radius:0 3px 3px 0;background:var(--accent);}
.s-item.gold{color:var(--gold);}
.s-item.gold:hover{background:rgba(245,158,11,.06);}
.s-item.ai-item{color:#a78bfa;}
.s-item.ai-item:hover{background:rgba(167,139,250,.07);color:#c4b5fd;}
.s-ic{width:28px;height:28px;border-radius:7px;background:rgba(255,255,255,.04);display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:13px;}
.s-item.on .s-ic{background:rgba(37,99,235,.18);}
.s-item.gold .s-ic{background:rgba(245,158,11,.08);}
.s-item.ai-item .s-ic{background:rgba(167,139,250,.1);}
.s-badge{margin-left:auto;font-size:9px;padding:2px 6px;border-radius:4px;font-weight:700;background:var(--gold);color:#000;letter-spacing:.03em;}
.s-beta{margin-left:auto;font-size:9px;font-weight:700;padding:2px 6px;border-radius:4px;background:rgba(167,139,250,.15);border:0.5px solid rgba(167,139,250,.3);color:#a78bfa;letter-spacing:.03em;}
.s-divider{height:0.5px;background:rgba(255,255,255,.05);margin:4px 10px;}
.s-bot{padding:10px 10px 14px;flex-shrink:0;border-top:0.5px solid rgba(255,255,255,.05);margin-top:auto;}
.trial-card{display:none;}
.up-mini{width:100%;padding:8px;border:none;border-radius:7px;background:linear-gradient(90deg,var(--accent),var(--al));color:#fff;font-size:11.5px;font-weight:600;cursor:pointer;font-family:'Plus Jakarta Sans',sans-serif;transition:opacity .15s;}
.up-mini:hover{opacity:.88;}
.u-row{display:flex;align-items:center;gap:10px;padding:9px 10px;border-radius:9px;cursor:pointer;transition:background .12s;text-decoration:none;border:0.5px solid transparent;}
.u-row:hover{background:rgba(255,255,255,.04);border-color:rgba(255,255,255,.07);}
.u-av{width:30px;height:30px;border-radius:8px;background:linear-gradient(135deg,var(--accent),var(--al));display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px;flex-shrink:0;color:#fff;}
.u-info{min-width:0;flex:1;display:flex;flex-direction:column;gap:1px;}
.u-name{font-size:12.5px;font-weight:600;color:var(--text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.u-email{font-size:10px;color:var(--sub);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.sub-status-badge{display:inline-flex;align-items:center;gap:3px;font-size:9px;font-weight:700;padding:2px 6px;border-radius:4px;margin-top:3px;letter-spacing:.03em;}
.sub-status-badge.trial{background:rgba(245,158,11,.1);border:0.5px solid rgba(245,158,11,.22);color:var(--gold);}
.sub-status-badge.premium{background:rgba(37,99,235,.12);border:0.5px solid rgba(37,99,235,.28);color:var(--al);}
.sub-status-badge.automated{background:rgba(245,158,11,.1);border:0.5px solid rgba(245,158,11,.22);color:var(--gold);}
.sub-status-badge.autosignals{background:rgba(16,185,129,.12);border:0.5px solid rgba(16,185,129,.28);color:var(--green);}
.s-logout{display:flex;align-items:center;gap:8px;padding:6px 10px;border-radius:7px;font-size:11.5px;font-weight:500;color:rgba(239,68,68,.45);cursor:pointer;transition:all .12s;margin-top:2px;}
.s-logout:hover{background:rgba(239,68,68,.07);color:var(--red);}
.live-dot-nav{display:inline-block;width:7px;height:7px;border-radius:50%;background:var(--green);animation:flicker 3.5s infinite;box-shadow:0 0 5px var(--green);}
@keyframes flicker{0%,100%{opacity:1;transform:scale(1);}15%{opacity:.88;transform:scale(.95);}30%{opacity:1;transform:scale(1.03);}45%{opacity:.92;transform:scale(.97);}60%{opacity:1;transform:scale(1.06);}75%{opacity:.9;transform:scale(.94);}90%{opacity:1;transform:scale(1.02);}}"""

NEW_NAV = f"""  <!-- SIDEBAR -->
  <nav class="sidebar" id="sidebar">
    <a class="s-logo" href="https://trenai.vercel.app" style="text-decoration:none;color:inherit;">
      <span class="s-logo-dot"></span>
      tren<span>.</span>
    </a>

    <div class="s-nav">
      <div class="s-section-label">Trading</div>
{nav_html}

      <div class="s-divider"></div>
      <div class="s-section-label">Tools</div>
{tools_html}

      <div class="s-divider"></div>
      <div class="s-section-label">Misc</div>
{misc_html}
    </div>

    <div class="s-bot">
      <a class="u-row" onclick="navTo('https://trenai.vercel.app/settings')">
        <div class="u-av" id="s-av">T</div>
        <div class="u-info">
          <div class="u-name" id="s-nm">Trader</div>
          <div class="u-email" id="s-email-display">\u2014</div>
          <span class="sub-status-badge trial" id="sidebar-plan-badge">\u26a1 Trial</span>
        </div>
      </a>
      <div class="s-logout" onclick="doLogout()">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        Sign out
      </div>
    </div>
  </nav>"""

# ── navTo snippet to inject if missing ──
NAVTO_SNIPPET = """
let _navLock = false;
function navTo(url){
  if(_navLock)return;
  _navLock=true;
  setTimeout(()=>{_navLock=false;},800);
  try{
    const s=localStorage.getItem('tren_session');
    if(s){ const encoded=encodeURIComponent(btoa(s)); url+=(url.includes('?')?'&':'?')+'_t='+encoded; }
  }catch(e){}
  window.location.href=url;
}"""

# ── Replace CSS ──
css_patterns = [
    re.compile(r'/\* \u2500\u2500 SIDEBAR \u2500\u2500 \*/.+?(?=/\* \u2500\u2500 MAIN)', re.DOTALL),
    re.compile(r'/\*[^\*]*SIDEBAR[^\*]*\*/.+?(?=/\*[^\*]*MAIN[^\*]*\*/)', re.DOTALL),
    re.compile(r'\.sidebar\{.+?(?=/\* \u2500\u2500)', re.DOTALL),
]
replaced_css = False
for pat in css_patterns:
    if pat.search(content):
        content = pat.sub(NEW_CSS + '\n\n', content)
        replaced_css = True
        break
if not replaced_css:
    print(f"  \u26a0  CSS block not found \u2014 skipping CSS replacement")

# ── Replace sidebar HTML ──
nav_pattern = re.compile(r'<!--\s*SIDEBAR\s*-->.*?</nav>', re.DOTALL)
if nav_pattern.search(content):
    content = nav_pattern.sub(NEW_NAV, content)
else:
    print(f"  \u26a0  Sidebar HTML not found \u2014 skipping HTML replacement")

# ── Inject navTo if missing ──
if 'function navTo' not in content:
    content = content.replace('</body>', NAVTO_SNIPPET + '\n</body>', 1)
    print("  + Injected navTo()")

if content != original:
    with open(filepath, 'w', encoding='utf-8') as fh:
        fh.write(content)
    print("  \u2713  Updated")
else:
    print("  \u2013  No changes (already up to date?)")
PYEOF

# ── Find all matching HTML files ─────────────────────────────
echo -e "${YELLOW}🔍 Scanning for Tren HTML pages...${NC}"

mapfile -t FILES < <(
  grep -rl 'class="sidebar"' . \
    --include="*.html" \
    --exclude-dir=".git" \
    --exclude-dir="node_modules" \
    --exclude-dir=".next" \
    --exclude-dir="dist" \
    2>/dev/null
)

if [ ${#FILES[@]} -eq 0 ]; then
  echo -e "${RED}✗ No matching HTML files found. Are you in the right directory?${NC}"
  exit 1
fi

echo -e "${GREEN}Found ${#FILES[@]} file(s):${NC}"
for f in "${FILES[@]}"; do echo "  → $f"; done
echo ""

# ── Process each file ────────────────────────────────────────
UPDATED=0

for FILE in "${FILES[@]}"; do
  echo -e "${YELLOW}Processing:${NC} $FILE"
  cp "$FILE" "${FILE}.bak"
  python3 "$PYWORKER" "$FILE"
  UPDATED=$((UPDATED + 1))
  echo ""
done

echo -e "${GREEN}✅ Done! $UPDATED file(s) processed.${NC}"
echo -e "   Backups saved as ${YELLOW}<filename>.bak${NC}"
echo ""
echo "To remove backups:"
echo -e "  ${YELLOW}find . -name '*.bak' -not -path './node_modules/*' -delete${NC}"