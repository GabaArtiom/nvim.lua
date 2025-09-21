local M = {}

-- List of available themes
local themes = {
  "onedark",
  "tokyonight",
  "catppuccin",
  "nord",
  "gruvbox",
  "kanagawa",
  "nightfox",
  "github_dark",
  "ayu_dark",
  "ayu_light",
  "everforest",
  "mountain",
  "rosepine",
  "material",
  "palenight",
}

-- Function to change theme
local function change_theme(theme_name)
  local base46 = require("base46")
  local chadrc = require("chadrc")

  -- Update theme in config
  chadrc.ui.theme = theme_name

  -- Recompile and reload theme
  base46.compile(chadrc.ui)
  base46.load_all_highlights()

  print("Theme changed to: " .. theme_name)
end

-- Theme picker using vim.ui.select
function M.pick_theme()
  vim.ui.select(themes, {
    prompt = "Select theme:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      change_theme(choice)
    end
  end)
end

-- Quick theme toggle between light/dark variants
function M.toggle_theme()
  local current = require("chadrc").ui.theme
  local toggle_map = {
    onedark = "github_light",
    github_light = "onedark",
    github_dark = "ayu_light",
    ayu_light = "github_dark",
    gruvbox = "everforest",
    everforest = "gruvbox",
  }

  local new_theme = toggle_map[current] or "onedark"
  change_theme(new_theme)
end

return M