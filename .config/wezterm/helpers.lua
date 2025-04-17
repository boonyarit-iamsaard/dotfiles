local helpers = {}

function helpers.get_scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Dracula (Official)" -- Dark theme
	else
		return "Dracula (Official)" -- Light theme
	end
end

function helpers.get_arrow_foreground_color(appearance, is_first_tab)
	if appearance:find("Dark") then
		if is_first_tab then
			return "#bd93f9"
		else
			return "#282a36"
		end
	else
		if is_first_tab then
			return "#bd93f9"
		else
			return "#282a36"
		end
	end
end

return helpers
