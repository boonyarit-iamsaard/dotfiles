-- Palette for the Dark 2026 colorscheme.
--
-- Every value below is transcribed from dark-2026.jsonc. Keys from the VS Code
-- theme are named in comments so the two can be diffed by hand later.
--
-- VS Code colors carry an alpha channel; Neovim highlights do not. Values that
-- are translucent upstream are kept here at their real alpha and flattened
-- against the surface they sit on via blend(), so the source of truth stays the
-- theme rather than a hand-eyeballed approximation.

local M = {}

---@param hex string "#rrggbb"
---@return integer, integer, integer
local function decode(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

--- Flatten a translucent color onto an opaque backdrop.
---@param fg string "#rrggbb" or "#rrggbbaa"
---@param bg string opaque "#rrggbb" backdrop
---@param alpha? number 0..1, overrides any alpha encoded in `fg`
---@return string "#rrggbb"
local function blend(fg, bg, alpha)
  if alpha == nil then
    alpha = #fg == 9 and tonumber(fg:sub(8, 9), 16) / 255 or 1
  end
  local fr, fg_, fb = decode(fg)
  local br, bg_, bb = decode(bg)
  local mix = function(a, b)
    return math.floor(a * alpha + b * (1 - alpha) + 0.5)
  end
  return string.format("#%02x%02x%02x", mix(fr, br), mix(fg_, bg_), mix(fb, bb))
end

M.blend = blend

-- ---------------------------------------------------------------------------
-- Surfaces
-- ---------------------------------------------------------------------------
M.bg = "#121314" -- editor.background
M.bg_panel = "#191a1b" -- sideBar / statusBar / panel / terminal.background
M.bg_float = "#202122" -- editorWidget.background / menu.background
M.bg_line = "#242526" -- editor.lineHighlightBackground
M.bg_inactive = "#2c2d2e" -- list.inactiveSelectionBackground
M.border = "#2a2b2c" -- panel.border / widget.border
M.indent = "#1f1f1f" -- editorIndentGuide.background1 / editorRuler.foreground

-- Translucent overlays, flattened onto the surface each one covers.
M.bg_visual = blend("#276782dd", M.bg) -- editor.selectionBackground
M.bg_search = blend("#27678280", M.bg) -- editor.findMatchHighlightBackground
M.bg_search_cur = blend("#27678290", M.bg) -- editor.findMatchBackground
M.bg_word = blend("#27678250", M.bg) -- editor.wordHighlightBackground
M.bg_bracket = blend("#3994bc55", M.bg) -- editorBracketMatch.background
M.bg_sel_list = blend("#ffffff22", M.bg_panel) -- list.activeSelectionBackground
M.bg_hover = blend("#ffffff14", M.bg_panel) -- list.hoverBackground
M.bg_sel_menu = blend("#ffffff26", M.bg_float) -- editorSuggestWidget.selectedBackground

-- ---------------------------------------------------------------------------
-- Foregrounds
-- ---------------------------------------------------------------------------
M.fg = "#bbbebf" -- editor.foreground
M.fg_ui = "#bfbfbf" -- foreground (chrome text)
M.fg_dim = "#8c8c8c" -- descriptionForeground / statusBar.foreground
M.fg_disabled = "#555555" -- disabledForeground
M.fg_gutter = "#474747" -- editorLineNumber.foreground
M.fg_term = "#cccccc" -- terminal.foreground
M.whitespace = blend("#8c8c8c4d", M.bg) -- editorWhitespace.foreground

-- ---------------------------------------------------------------------------
-- Accent
-- ---------------------------------------------------------------------------
M.accent = "#3994bc" -- focusBorder / tab.activeBorderTop
M.accent_dim = "#297aa0" -- button.background
M.accent_badge = "#307e9f" -- badge.background
M.link = "#48a0c7" -- textLink.foreground / list.highlightForeground
M.link_active = "#53a5ca" -- textLink.activeForeground
M.on_accent = "#ffffff" -- button.foreground / badge.foreground

-- ---------------------------------------------------------------------------
-- Syntax
--
-- These are the *effective* token colors. dark-2026.jsonc layers a GitHub Dark
-- ruleset after an older Dark+ one, and in VS Code later rules win, so the
-- Dark+ values (#569cd6, #ce9178, ...) never render. See the scope each color
-- resolves from in the comments.
-- ---------------------------------------------------------------------------
M.comment = "#8b949e" -- comment
M.string = "#a5d6ff" -- string
M.constant = "#79c0ff" -- constant / constant.numeric / support.*
M.keyword = "#ff7b72" -- keyword / storage
M.func = "#d2a8ff" -- entity.name.function
M.type = "#ffa657" -- entity.name.type / variable.parameter
M.tag = "#7ee787" -- entity.name.tag
M.text = "#c9d1d9" -- variable.other / meta.object.member
M.key = "#9cdcfe" -- meta.object-literal.key
M.invalid = "#f44747" -- invalid
M.deleted = "#ffa198" -- markup.deleted

-- ---------------------------------------------------------------------------
-- Diagnostics
-- ---------------------------------------------------------------------------
M.error = "#f48771" -- errorForeground
M.warn = "#cca700" -- notificationsWarningIcon.foreground
M.info = "#3a94bc" -- notificationsInfoIcon.foreground
M.hint = "#86cf86" -- charts.green
M.ok = "#73c991" -- gitDecoration.addedResourceForeground

-- ---------------------------------------------------------------------------
-- Git / diff
-- ---------------------------------------------------------------------------
M.git_add = "#73c991" -- gitDecoration.addedResourceForeground
M.git_change = "#e5ba7d" -- gitDecoration.modifiedResourceForeground
M.git_delete = "#f48771" -- gitDecoration.deletedResourceForeground
M.git_ignored = "#8c8c8c" -- gitDecoration.ignoredResourceForeground

M.gutter_add = "#72c892" -- editorGutter.addedBackground
M.gutter_change = "#0078d4" -- editorGutter.modifiedBackground
M.gutter_delete = "#f28772" -- editorGutter.deletedBackground

M.diff_add = blend("#347d3926", M.bg) -- diffEditor.insertedLineBackground
M.diff_delete = blend("#c93c3726", M.bg) -- diffEditor.removedLineBackground
M.diff_text_add = blend("#57ab5a4d", M.bg) -- diffEditor.insertedTextBackground
M.diff_text_del = blend("#f470674d", M.bg) -- diffEditor.removedTextBackground
M.diff_change = blend("#0078d426", M.bg) -- editorGutter.modifiedBackground @ line alpha

-- ---------------------------------------------------------------------------
-- Charts (spare accents for plugins that want a wider spread)
-- ---------------------------------------------------------------------------
M.blue = "#57a3f8" -- charts.blue
M.green = "#86cf86" -- charts.green
M.red = "#ef8773" -- charts.red
M.purple = "#ad80d7" -- charts.purple
M.orange = "#cd861a" -- charts.orange
M.yellow = "#e0b97f" -- charts.yellow

-- ---------------------------------------------------------------------------
-- Terminal (16 ANSI slots)
--
-- dark-2026.jsonc leaves every terminal.ansi* key commented out, so VS Code
-- falls back to its built-in defaults. Those defaults are reproduced here, and
-- they are the same values used by the Windows Terminal and tmux ports.
-- ---------------------------------------------------------------------------
M.ansi = {
  black = "#000000",
  red = "#cd3131",
  green = "#0dbc79",
  yellow = "#e5e510",
  blue = "#2472c8",
  magenta = "#bc3fbc",
  cyan = "#11a8cd",
  white = "#e5e5e5",
  bright_black = "#666666",
  bright_red = "#f14c4c",
  bright_green = "#23d18b",
  bright_yellow = "#f5f543",
  bright_blue = "#3b8eea",
  bright_magenta = "#d670d6",
  bright_cyan = "#29b8db",
  bright_white = "#e5e5e5",
}

return M
