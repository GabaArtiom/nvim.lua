return {
  -- Volt framework (standalone 2025 version)
  {
    "nvzone/volt",
    lazy = true,
  },

  -- Base46 for theme support (2025 best practices)
  {
    "NvChad/base46",
    lazy = false,
    priority = 1000,
    build = function()
      require("base46").load_all_highlights()
    end,
    config = function()
      -- Set base46_cache path (best practice 2025)
      vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"

      -- Create cache directory
      vim.fn.mkdir(vim.g.base46_cache, "p")

      -- Load chadrc configuration
      local chadrc = require("chadrc")

      -- Initialize base46 with 2025 structure
      local base46 = require("base46")
      base46.compile(chadrc.base46 or chadrc.ui)

      -- Load all highlights for performance
      base46.load_all_highlights()
    end,
  },

  -- NvChad UI components
  {
    "NvChad/ui",
    dependencies = { "NvChad/base46", "nvzone/volt" },
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },
}