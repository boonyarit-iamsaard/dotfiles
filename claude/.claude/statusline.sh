#!/bin/sh
# Usage-focused status line for Claude Code.
#
#   main │ Opus 5 medium │ 🔥 ██████░░░░ 34% │ 28.8k/1.0M │ $4.10 │ +82/-13
#   ├ 5h ████░░░░░░  38%  ↺ 1h02m
#   └ 7d ████████░░  81%  ↺ 17h00m
#   ⚡fast 🎨explanatory
#
# Rate-limit rows only appear for Pro/Max plans, and each window can be absent
# independently. The flag row only appears when something is off its default.
#
# A status line re-renders constantly, so this spawns exactly two processes: one
# jq to read the payload and one git to name the branch. Everything else is
# POSIX shell arithmetic — no awk, no date, no subshell per field.

input=$(cat)

E=$(printf '\033')
RESET="${E}[0m"
MUTED="${E}[38;5;244m"   # secondary text
DIM="${E}[38;5;240m"     # tertiary — tree glyphs, separators
CYAN="${E}[38;5;51m"
GREEN="${E}[1;38;5;77m"
YELLOW="${E}[1;38;5;220m"
RED="${E}[1;38;5;196m"
EMPTY="${E}[38;5;236m"   # unfilled bar track
SEP="${DIM}│${RESET}"

BLOCK='█'
# Ten colours for ten cells: the filled span ramps green → red across itself.
GRADIENT='77 113 149 185 221 220 214 208 202 196'

# One jq pass. Percentages and cost are rounded here because POSIX shell has no
# float arithmetic, and reset times become plain seconds-remaining so the script
# never has to shell out to date. Absent rate limits stay empty strings, which
# is what distinguishes "no Pro/Max plan" from "0% used".
fields=$(printf '%s' "$input" | jq -j '
  def opt(f): if f == null then "" else (f | round) end;
  def until(f): if f == null then "" else ((f - now) | floor) end;
  [ (.model.display_name // "?")
  , (.effort.level // "")
  , ((.context_window.used_percentage // 0) | round)
  , ((.context_window.total_input_tokens // 0)
     + (.context_window.total_output_tokens // 0) | round)
  , ((.context_window.context_window_size // 200000) | round)
  , (((.cost.total_cost_usd // 0) * 100) | round)
  , opt(.rate_limits.five_hour.used_percentage)
  , until(.rate_limits.five_hour.resets_at)
  , opt(.rate_limits.seven_day.used_percentage)
  , until(.rate_limits.seven_day.resets_at)
  , (.fast_mode // false)
  , (.thinking.enabled // false)
  , (.output_style.name // "default")
  , (.workspace.current_dir // .cwd // "")
  , (.workspace.git_worktree // "")
  , (.cost.total_lines_added // 0)
  , (.cost.total_lines_removed // 0)
  ] | map(tostring) | join("\u001f")' 2>/dev/null)

# Split on unit separator. A non-whitespace IFS keeps empty fields in position
# instead of collapsing them, and `read` splits the same way under dash, bash
# and zsh alike.
IFS=$(printf '\037')
read -r model effort ctx_pct tokens ctx_size cents \
  fh_pct fh_left sd_pct sd_left fast thinking style cwd worktree added removed <<EOF
$fields
EOF
unset IFS

# jq missing or payload unparseable — say so rather than rendering a blank bar.
[ -n "$model" ] || { printf '%sstatusline: cannot parse payload%s' "$DIM" "$RESET"; exit 0; }

# --- helpers ---

color_for() { # used-percent -> green < 50, yellow < 80, red otherwise
  if   [ "$1" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$1" -ge 50 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"
  fi
}

filled() { # used-percent -> how many of the ten cells are lit
  _n=$(( ($1 * 10 + 50) / 100 ))
  [ "$_n" -gt 10 ] && _n=10
  [ "$_n" -lt 0 ] && _n=0
  printf '%s' "$_n"
}

gradient_bar() { # used-percent — colour ramps across the filled span
  _n=$(filled "$1") _out='' _i=0
  for _c in $GRADIENT; do
    _i=$(( _i + 1 ))
    if [ "$_i" -le "$_n" ]
      then _out="${_out}${E}[38;5;${_c}m${BLOCK}"
      else _out="${_out}${EMPTY}${BLOCK}"
    fi
  done
  printf '%s%s' "$_out" "$RESET"
}

solid_bar() { # used-percent — one severity colour for the whole filled span
  _n=$(filled "$1") _out=$(color_for "$1") _i=0
  while [ "$_i" -lt 10 ]; do
    _i=$(( _i + 1 ))
    [ "$_i" -eq $(( _n + 1 )) ] && _out="${_out}${EMPTY}"
    _out="${_out}${BLOCK}"
  done
  printf '%s%s' "$_out" "$RESET"
}

human() { # token count -> 16.7k, 1.2M
  if   [ "$1" -ge 1000000 ]; then printf '%d.%dM' $(( $1 / 1000000 )) $(( $1 % 1000000 / 100000 ))
  elif [ "$1" -ge 1000 ];    then printf '%d.%dk' $(( $1 / 1000 ))    $(( $1 % 1000 / 100 ))
  else printf '%d' "$1"
  fi
}

countdown() { # seconds remaining -> 3d4h, 1h02m, 5m, now
  [ "$1" -le 0 ] && { printf 'now'; return; }
  _d=$(( $1 / 86400 )) _h=$(( $1 % 86400 / 3600 )) _m=$(( $1 % 3600 / 60 ))
  if   [ "$_d" -gt 0 ]; then printf '%dd%dh' "$_d" "$_h"
  elif [ "$_h" -gt 0 ]; then printf '%dh%02dm' "$_h" "$_m"
  else printf '%dm' "$_m"
  fi
}

# --- line 1: branch, model, context, cost ---

# symbolic-ref is the cheap path and fails on a detached HEAD, where a short sha
# is the only meaningful name. Outside a repo, fall back to the directory name.
branch=''
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null) ||
    branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null) || branch=''
fi
[ -n "$branch" ] || branch=$(basename "${cwd:-?}")

line1="${CYAN}${branch}${RESET}"
[ -n "$worktree" ] && line1="${line1}${DIM}@${worktree}${RESET}"
line1="${line1} ${SEP} ${model}"
[ -n "$effort" ] && line1="${line1} ${MUTED}${effort}${RESET}"
line1="${line1} ${SEP} 🔥 $(gradient_bar "$ctx_pct") $(color_for "$ctx_pct")${ctx_pct}%${RESET}"
line1="${line1} ${SEP} ${MUTED}$(human "$tokens")/$(human "$ctx_size")${RESET}"
line1="${line1} ${SEP} \$$(( cents / 100 )).$(printf '%02d' $(( cents % 100 )))"
if [ "$added" -gt 0 ] || [ "$removed" -gt 0 ]; then
  line1="${line1} ${SEP} ${MUTED}+${added}/-${removed}${RESET}"
fi

out=$line1

# --- rate-limit rows (Pro/Max only) ---

limit_row() { # glyph label used-percent seconds-left
  _row="${DIM}$1${RESET} ${MUTED}$2${RESET} $(solid_bar "$3") $(color_for "$3")$(printf '%3d' "$3")%${RESET}"
  [ -n "$4" ] && _row="${_row}  ${DIM}↺ $(countdown "$4")${RESET}"
  printf '%s' "$_row"
}

# The tree glyph depends on which rows are actually present: with only one
# window on the payload, that row is the last one and gets the elbow.
if [ -n "$fh_pct" ]; then
  glyph='├'
  [ -n "$sd_pct" ] || glyph='└'
  out="${out}
$(limit_row "$glyph" '5h' "$fh_pct" "$fh_left")"
fi
if [ -n "$sd_pct" ]; then
  out="${out}
$(limit_row '└' '7d' "$sd_pct" "$sd_left")"
fi

# --- flag row — only what is off its default ---

flags=''
[ "$fast" = true ] && flags="${flags} ⚡fast"
[ "$thinking" = false ] && flags="${flags} 💤thinking off"
[ "$style" != default ] && flags="${flags} 🎨${style}"
if [ -n "$flags" ]; then
  out="${out}
${MUTED}${flags# }${RESET}"
fi

printf '%s' "$out"
