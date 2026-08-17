#!/bin/sh
# Usage-focused status line for Claude Code.
#
#   main │ Opus 5 medium │ 🔥 ██████░░░░ 34% │ $4.10 │ 28.8k/1.0M
#   ├ 5h ████░░░░░░  38%  ↺ 1h02m
#   └ 7d ████████░░  81%  ↺ 17h00m
#
# Rate-limit rows only appear for Pro/Max plans.
input=$(cat)

# Publish the payload for the Claude Usage Monitor to read.
# Temp file + rename so a reader never catches a half-written document.
{ printf '%s' "$input" > "$HOME/.claude/usage-input.json.tmp" &&
  mv -f "$HOME/.claude/usage-input.json.tmp" "$HOME/.claude/usage-input.json"; } 2>/dev/null || true

RESET='\033[0m'
MUTED='\033[38;5;244m'  # secondary text
DIM='\033[38;5;240m'    # tertiary text — tree glyphs, separators
CYAN='\033[38;5;51m'
SEP="${DIM}│${RESET}"

BAR_WIDTH=10

# One jq pass — a statusline runs on every render, so keep the process count low.
fields=$(printf '%s' "$input" | jq -r '
  [ .model.display_name // "?"
  , .effort.level // ""
  , (.context_window.used_percentage // 0)
  , (.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)
  , (.context_window.context_window_size // 200000)
  , (.cost.total_cost_usd // 0)
  , (.rate_limits.five_hour.used_percentage // "")
  , (.rate_limits.five_hour.resets_at // "")
  , (.rate_limits.seven_day.used_percentage // "")
  , (.rate_limits.seven_day.resets_at // "")
  , (.fast_mode // false)
  , (.thinking.enabled // false)
  , .output_style.name // "default"
  ] | map(tostring) | join("")' 2>/dev/null)

# Split on unit-separator. A non-whitespace IFS keeps empty fields (absent rate
# limits, absent effort) in position instead of collapsing them away, and `read`
# splits the same way under dash, bash and zsh alike.
IFS=$(printf '\037') read -r model effort ctx_used tok ctx_size cost \
  fh_used fh_reset sd_used sd_reset fast thinking style <<EOF
$fields
EOF

# Pick a color from a used-percentage: green < 50, yellow < 80, red otherwise.
color_for() {
  awk -v u="${1:-0}" 'BEGIN{
    if (u >= 80) printf "\033[01;38;5;196m";
    else if (u >= 50) printf "\033[01;38;5;220m";
    else printf "\033[01;38;5;77m";
  }'
}

# Round a (possibly fractional) number to an integer.
round() { awk -v n="${1:-0}" 'BEGIN{ printf "%d", (n < 0 ? n - 0.5 : n + 0.5) }'; }

# Human-readable token count (e.g. 16.7k, 1.2M).
human() {
  awk -v n="${1:-0}" 'BEGIN{
    if (n >= 1000000) printf "%.1fM", n/1000000;
    else if (n >= 1000) printf "%.1fk", n/1000;
    else printf "%d", n;
  }'
}

# Time-until from a unix epoch (e.g. 3d4h, 1h02m, 5m, now).
countdown() {
  now=$(date +%s)
  d=$(( ${1:-0} - now ))
  [ "$d" -lt 0 ] && { printf "now"; return; }
  days=$(( d / 86400 )); hrs=$(( (d % 86400) / 3600 )); mins=$(( (d % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then printf "%dd%dh" "$days" "$hrs"
  elif [ "$hrs" -gt 0 ]; then printf "%dh%02dm" "$hrs" "$mins"
  else printf "%dm" "$mins"; fi
}

# Filled bar whose colour ramps green → red across the filled span.
gradient_bar() {
  awk -v u="${1:-0}" -v w="${2:-10}" 'BEGIN{
    split("77 113 149 185 221 220 214 208 202 196", pal, " ");
    n = int(w * u / 100 + 0.5);
    if (n > w) n = w;
    for (i = 1; i <= w; i++) {
      if (i <= n) {
        ci = (w > 1) ? int((i - 1) * 9 / (w - 1)) + 1 : 10;
        printf "\033[38;5;%dm█", pal[ci];
      } else printf "\033[38;5;236m█";
    }
    printf "\033[0m";
  }'
}

# Flat bar in a single severity colour.
solid_bar() {
  awk -v u="${1:-0}" -v w="${2:-10}" -v c="$(color_for "${1:-0}")" 'BEGIN{
    n = int(w * u / 100 + 0.5);
    if (n > w) n = w;
    printf "%s", c;
    for (i = 1; i <= n; i++) printf "█";
    printf "\033[38;5;236m";
    for (i = n + 1; i <= w; i++) printf "█";
    printf "\033[0m";
  }'
}

# --- Line 1: context, model, cost ---
branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] && branch=$style

cu=$(round "$ctx_used")
ctx_col=$(color_for "$cu")
line1="${CYAN}${branch}${RESET} ${SEP} ${model}"
[ -n "$effort" ] && line1="${line1} ${MUTED}${effort}${RESET}"
line1="${line1} ${SEP} 🔥 $(gradient_bar "$cu" "$BAR_WIDTH") ${ctx_col}${cu}%${RESET}"
line1="${line1} ${SEP} ${MUTED}$(human "$tok")/$(human "$ctx_size")${RESET}"
line1="${line1} ${SEP} $(awk -v c="${cost:-0}" 'BEGIN{ printf "$%.2f", c }')"

out=$line1

# --- Rate-limit rows (Pro/Max only) ---
limit_row() { # glyph label used resets_at
  col=$(color_for "$3")
  u=$(round "$3")
  row="${DIM}$1${RESET} ${MUTED}$2${RESET} $(solid_bar "$u" "$BAR_WIDTH") ${col}$(printf '%3d' "$u")%${RESET}"
  [ -n "$4" ] && row="${row}  ${DIM}↺ $(countdown "$4")${RESET}"
  printf '%s' "$row"
}

if [ -n "$fh_used" ] || [ -n "$sd_used" ]; then
  [ -n "$fh_used" ] && out="${out}
$(limit_row '├' '5h' "$fh_used" "$fh_reset")"
  [ -n "$sd_used" ] && out="${out}
$(limit_row '└' '7d' "$sd_used" "$sd_reset")"
fi

# --- Mode flags — only shown when off the defaults ---
flags=""
[ "$fast" = "true" ] && flags="${flags} ⚡fast"
[ "$thinking" != "true" ] && flags="${flags} 💤thinking off"
[ "$style" != "default" ] && flags="${flags} 🎨${style}"
[ -n "$flags" ] && out="${out}
${MUTED}${flags# }${RESET}"

printf "%b" "$out"
