local M = {}

-- Base46 configuration (2025 structure)
M.base46 = {
  theme = "doomchad",
  transparency = false,

  -- Color overrides for better customization
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },

  -- Theme picker configuration
  theme_toggle = {
    "doomchad",
    "tokyonight",
    "catppuccin",
    "nord",
    "gruvbox",
    "kanagawa",
    "nightfox",
    "github_dark",
    "ayu_dark",
    "everforest",
    "rosepine",
  },
}

-- UI configuration
M.ui = {
  statusline = {
    theme = "default",
  },

  tabufline = {
    enabled = false,
    lazyload = true,
  },

  cmp = {
    style = "default",
  },
}

return M