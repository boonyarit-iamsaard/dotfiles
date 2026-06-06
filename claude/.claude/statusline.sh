#!/bin/sh
# Usage-focused status line for Claude Code.
# Shows: session context window, 5-hour rate limit, and weekly (7-day) rate limit,
# each as "used% (remaining% left)". Rate limits only appear for Pro/Max plans.
input=$(cat)

RESET='\033[0m'
MUTED='\033[90m'   # bright black (gray) — readable secondary text
GRAY='\033[90m'    # bright black — subtle separators
SEP="${GRAY}│${RESET}"

# Pick a color from a used-percentage: green < 50, yellow < 80, red otherwise.
color_for() {
  awk -v u="${1:-0}" 'BEGIN{
    if (u >= 80) printf "\033[01;31m";
    else if (u >= 50) printf "\033[01;33m";
    else printf "\033[01;32m";
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

# Time-until from a unix epoch (e.g. 2h13m, 3d4h, now).
countdown() {
  now=$(date +%s)
  d=$(( ${1:-0} - now ))
  [ "$d" -lt 0 ] && { printf "now"; return; }
  days=$(( d / 86400 ))
  hrs=$(( (d % 86400) / 3600 ))
  mins=$(( (d % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then printf "%dd%dh" "$days" "$hrs"
  elif [ "$hrs" -gt 0 ]; then printf "%dh%02dm" "$hrs" "$mins"
  else printf "%dm" "$mins"; fi
}

# --- Context window ---
ctx_used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
ctx_remain=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // empty')
in_tok=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(printf '%s' "$input" | jq -r '.context_window.total_output_tokens // 0')
ctx_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 200000')

if [ -n "$ctx_used" ]; then
  cu=$(round "$ctx_used")
  cr=$(round "${ctx_remain:-$((100 - cu))}")
  col=$(color_for "$cu")
  tok=$(human $(( in_tok + out_tok )))
  ctx_seg="${col}ctx ${cu}%${RESET} ${MUTED}(${cr}% left · ${tok}/$(human "$ctx_size"))${RESET}"
else
  ctx_seg="${MUTED}ctx —${RESET}"
fi

# --- 5-hour rate limit ---
fh_used=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
fh_reset=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$fh_used" ]; then
  u=$(round "$fh_used"); r=$(( 100 - u )); col=$(color_for "$u")
  rs=""; [ -n "$fh_reset" ] && rs=" ${MUTED}↺$(countdown "$fh_reset")${RESET}"
  fh_seg="${col}5h ${u}%${RESET} ${MUTED}(${r}% left)${RESET}${rs}"
else
  fh_seg="${MUTED}5h —${RESET}"
fi

# --- Weekly (7-day) rate limit ---
sd_used=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
sd_reset=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$sd_used" ]; then
  u=$(round "$sd_used"); r=$(( 100 - u )); col=$(color_for "$u")
  rs=""; [ -n "$sd_reset" ] && rs=" ${MUTED}↺$(countdown "$sd_reset")${RESET}"
  wk_seg="${col}7d ${u}%${RESET} ${MUTED}(${r}% left)${RESET}${rs}"
else
  wk_seg="${MUTED}7d —${RESET}"
fi

printf "%b %b %b %b %b" "$ctx_seg" "$SEP" "$fh_seg" "$SEP" "$wk_seg"
