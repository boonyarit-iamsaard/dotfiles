local helpers = {}

-- Function to get macOS appearance
function helpers.get_macos_appearance()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:match("Dark") and "dark" or "light"
  end

  return "dark" -- fallback
end

return helpers
