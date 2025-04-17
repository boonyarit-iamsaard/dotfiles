local wezterm = require("wezterm")
local helpers = require("helpers")

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

wezterm.on("window-config-reloaded", function(window)
	local appearance = wezterm.gui.get_appearance()
	window:set_config_overrides({
		color_scheme = helpers.get_scheme_for_appearance(appearance),
	})
end)

config.front_end = "OpenGL"
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"
config.font = wezterm.font_with_fallback({
	{ family = "MesloLGS Nerd Font Mono" },
	{ family = "Hack Nerd Font Mono" },
	{ family = "FiraCode Nerd Font Mono" },
	{ family = "JetBrainsMono Nerd Font Mono" },
	{ family = "JetBrains Mono" },
	{ family = "Noto Color Emoji" },
})
config.font_size = 16
config.line_height = 1.3
config.window_decorations = "RESIZE"
config.window_padding = {
	-- left = 2,
	-- right = 2,
	-- top = 2,
	bottom = 0,
}
config.use_fancy_tab_bar = false

-- config.background = {
-- 	{
-- 		source = {
-- 			File = "/Users/" .. os.getenv("USER") .. "/.config/wezterm/background.png",
-- 		},
-- 		hsb = {
-- 			hue = 1.0,
-- 			saturation = 1.00,
-- 			brightness = 0.25,
-- 		},
-- 		-- attachment = { Parallax = 0.3 },
-- 		-- width = "100%",
-- 		-- height = "100%",
-- 	},
-- 	{
-- 		source = {
-- 			Color = "#1e1e2e",
-- 		},
-- 		width = "100%",
-- 		height = "100%",
-- 		opacity = 0.75,
-- 	},
-- }

-- tmux
config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 2000 }
config.keys = {
	{
		mods = "LEADER",
		key = "c",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		mods = "LEADER",
		key = "x",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		mods = "LEADER",
		key = "b",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		mods = "LEADER",
		key = "n",
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		mods = "LEADER",
		key = '"',
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		mods = "LEADER",
		key = "$",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		mods = "LEADER",
		key = "z",
		action = wezterm.action.TogglePaneZoomState,
	},
	{
		mods = "LEADER",
		key = "f",
		action = wezterm.action.ToggleFullScreen,
	},
	{
		mods = "LEADER",
		key = "h",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		mods = "LEADER",
		key = "j",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		mods = "LEADER",
		key = "k",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		mods = "LEADER",
		key = "l",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		mods = "LEADER",
		key = "LeftArrow",
		action = wezterm.action.AdjustPaneSize({ "Left", 5 }),
	},
	{
		mods = "LEADER",
		key = "RightArrow",
		action = wezterm.action.AdjustPaneSize({ "Right", 5 }),
	},
	{
		mods = "LEADER",
		key = "DownArrow",
		action = wezterm.action.AdjustPaneSize({ "Down", 5 }),
	},
	{
		mods = "LEADER",
		key = "UpArrow",
		action = wezterm.action.AdjustPaneSize({ "Up", 5 }),
	},
}

for i = 0, 9 do
	-- leader + number to activate that tab
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = wezterm.action.ActivateTab(i),
	})
end

-- tab bar
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true

-- tmux status
wezterm.on("update-right-status", function(window, _)
	local SOLID_LEFT_ARROW = ""
	local appearance = wezterm.gui.get_appearance()
	local is_first_tab = window:active_tab():tab_id() == 0
	local ARROW_FOREGROUND = { Foreground = { Color = helpers.get_arrow_foreground_color(appearance, is_first_tab) } }
	local prefix = ""

	if window:leader_is_active() then
		prefix = " " .. utf8.char(0x1f30a) -- ocean wave
		SOLID_LEFT_ARROW = utf8.char(0xe0b2)
	end

	window:set_left_status(wezterm.format({
		{ Background = { Color = "#8be9fd" } },
		{ Text = prefix },
		ARROW_FOREGROUND,
		{ Text = SOLID_LEFT_ARROW },
	}))
end)

return config
