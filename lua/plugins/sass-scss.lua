return {
  -- Enhanced SASS/SCSS support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Using CSS LSP for SCSS files (more stable)
        cssls = {
          settings = {
            css = {
              validate = true,
              lint = {
                unknownAtRules = "ignore"
              }
            },
            scss = {
              validate = true,
              lint = {
                unknownAtRules = "ignore"
              }
            },
            sass = {
              validate = true,
              lint = {
                unknownAtRules = "ignore"
              }
            }
          },
          filetypes = { "css", "scss", "sass", "less" }
        },
      },
    },
  },

  -- Treesitter parsers for SASS/SCSS
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "scss",
        "sass",
      })
    end,
  },

  -- SASS/SCSS syntax highlighting
  {
    "cakebaker/scss-syntax.vim",
    ft = { "scss", "sass" },
  },

  -- Mason tools for SASS/SCSS
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "stylelint",
      })
    end,
  },

  -- Auto compile SASS/SCSS on save
  {
    "tpope/vim-dispatch",
    ft = { "scss", "sass" },
    config = function()
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = { "*.scss", "*.sass" },
        callback = function()
          local file = vim.fn.expand("%:p")
          local output = vim.fn.expand("%:p:r") .. ".css"

          -- Check if sass command is available
          if vim.fn.executable("sass") == 1 then
            vim.cmd("silent! !sass " .. file .. " " .. output)
          end
        end,
      })
    end,
  },

  -- SASS/SCSS specific snippets
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load({
        include = { "scss", "sass", "css" }
      })
    end,
  },
}