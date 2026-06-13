#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# add_signin_button.sh
#
# Adds a "Sign In" button next to every "Start free trial"
# nav-cta link in all .html files (desktop nav + mobile menu).
#
# Usage:
#   chmod +x add_signin_button.sh
#   ./add_signin_button.sh                     # runs in current dir
#   ./add_signin_button.sh /path/to/html/files  # or pass a directory
# ─────────────────────────────────────────────────────────────

TARGET_DIR="${1:-.}"
SIGN_IN_URL="https://trenai.vercel.app/login-page"
SIGN_IN_HTML='<a href="'"$SIGN_IN_URL"'" class="nav-signin">Sign In</a>'

# ── Colour helpers ────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()   { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn() { echo -e "${YELLOW}[SKIP]${RESET}  $*"; }
err()  { echo -e "${RED}[ERR]${RESET}   $*"; }

# ── Sanity checks ─────────────────────────────────────────────
if [[ ! -d "$TARGET_DIR" ]]; then
  err "Directory not found: $TARGET_DIR"
  exit 1
fi

# Check for perl (used for reliable multi-line sed-like replacement)
if ! command -v perl &>/dev/null; then
  err "perl is required but not installed."
  exit 1
fi

# ── Inline CSS to inject (idempotent – only once per file) ────
SIGNIN_CSS='
    /* Sign In button – injected by add_signin_button.sh */
    a.nav-signin {
      font-size: 13px;
      font-weight: 500;
      color: rgba(240,244,255,0.65) !important;
      text-decoration: none;
      padding: 8px 16px;
      border-radius: 6px;
      border: 1px solid rgba(255,255,255,0.14);
      transition: color 0.2s, border-color 0.2s, background 0.2s;
    }
    a.nav-signin:hover {
      color: #f0f4ff !important;
      border-color: rgba(255,255,255,0.28);
      background: rgba(255,255,255,0.04);
    }'

# ── Find all HTML files ───────────────────────────────────────
mapfile -t HTML_FILES < <(find "$TARGET_DIR" -maxdepth 5 -name "*.html" | sort)

if [[ ${#HTML_FILES[@]} -eq 0 ]]; then
  warn "No .html files found in '$TARGET_DIR'."
  exit 0
fi

log "Found ${#HTML_FILES[@]} HTML file(s) in '$TARGET_DIR'"
echo ""

MODIFIED=0
SKIPPED=0

for FILE in "${HTML_FILES[@]}"; do
  echo -e "${BOLD}→ $FILE${RESET}"

  # ── Skip if already patched ───────────────────────────────
  if grep -q 'nav-signin' "$FILE"; then
    warn "Already contains 'nav-signin' – skipping."
    (( SKIPPED++ ))
    echo ""
    continue
  fi

  # ── Back up the original ──────────────────────────────────
  cp "$FILE" "${FILE}.bak"

  # ── Count nav-cta occurrences to report ──────────────────
  CTA_COUNT=$(grep -c 'class="nav-cta"' "$FILE" || true)

  if [[ "$CTA_COUNT" -eq 0 ]]; then
    warn "No 'nav-cta' button found – skipping."
    rm "${FILE}.bak"
    (( SKIPPED++ ))
    echo ""
    continue
  fi

  # ── 1. Insert Sign In BEFORE every nav-cta anchor ────────
  #    Matches:  <a href="..." class="nav-cta">...</a>
  #    Inserts the Sign In link immediately before it.
  perl -i -0pe '
    s|(<a\s[^>]*class="nav-cta"[^>]*>.*?</a>)|<a href="'"$SIGN_IN_URL"'" class="nav-signin">Sign In</a>\n    $1|gs
  ' "$FILE"

  # ── 2. Inject CSS into the first <style> block ───────────
  ESCAPED_CSS=$(printf '%s\n' "$SIGNIN_CSS" | sed 's/[&/\]/\\&/g; s/$/\\n/' | tr -d '\n')
  perl -i -0pe "s|(<style>)|<style>\n${ESCAPED_CSS}|s" "$FILE"

  # ── Verify the patch applied ─────────────────────────────
  if grep -q 'nav-signin' "$FILE"; then
    ok "Patched – inserted Sign In button next to $CTA_COUNT nav-cta instance(s)."
    (( MODIFIED++ ))
  else
    err "Patch failed. Restoring backup."
    mv "${FILE}.bak" "$FILE"
  fi

  echo ""
done

# ── Summary ───────────────────────────────────────────────────
echo "────────────────────────────────────────"
echo -e "${BOLD}Summary${RESET}"
echo -e "  ${GREEN}Modified : $MODIFIED${RESET}"
echo -e "  ${YELLOW}Skipped  : $SKIPPED${RESET}"
echo ""
echo -e "Backups saved as ${CYAN}<filename>.html.bak${RESET}"
echo "────────────────────────────────────────"