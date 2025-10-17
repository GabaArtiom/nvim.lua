return {
  -- Conform for formatting
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      formatters_by_ft = {
        ["javascript"] = { "prettierd", "prettier" },
        ["javascriptreact"] = { "prettierd", "prettier" },
        ["typescript"] = { "prettierd", "prettier" },
        ["typescriptreact"] = { "prettierd", "prettier" },
        ["vue"] = { "prettierd", "prettier" },
        ["css"] = { "stylelint", "prettier" },
        ["scss"] = { "stylelint", "prettier" },
        ["sass"] = { "stylelint", "prettier" },
        ["less"] = { "prettier" },
        ["html"] = { "prettierd", "prettier" },
        ["json"] = { "prettierd", "prettier" },
        ["jsonc"] = { "prettierd", "prettier" },
        ["yaml"] = { "prettierd", "prettier" },
        ["markdown"] = { "prettierd", "prettier" },
        ["markdown.mdx"] = { "prettierd", "prettier" },
        ["graphql"] = { "prettierd", "prettier" },
        ["handlebars"] = { "prettierd", "prettier" },
        ["php"] = { "prettier" },
      },
      formatters = {
        ["blade-formatter"] = {
          command = "blade-formatter",
          args = {
            "--stdin",
            "--indent-size=2",
            "--wrap-line-length=120",
            "--wrap-attributes=force-expand-multiline"
          },
          stdin = true,
        },
        ["php-cs-fixer"] = {
          command = vim.fn.expand("~/.local/bin/php-cs-fixer"),
          args = {
            "fix",
            "--rules=@PSR12,@Symfony",
            "--using-cache=no",
            "$FILENAME"
          },
          stdin = false,
        },
        prettier = {
          command = vim.fn.expand("~/.local/share/nvim/mason/bin/prettier"),
          args = function(_, ctx)
            local args = { "--stdin-filepath", "$FILENAME" }
            -- Explicitly set parser for PHP files
            if ctx.filetype == "php" then
              table.insert(args, "--parser")
              table.insert(args, "php")
            end
            return args
          end,
          stdin = true,
        },
        stylelint = {
          command = "stylelint",
          args = {
            "--fix",
            "--stdin",
            "--stdin-filename",
            "$FILENAME",
            "--config",
            vim.fn.expand("~/.config/nvim/.stylelintrc.json"),
          },
          stdin = true,
        },
      },
      format_on_save = false, -- Disable auto-format on save
    },
  },

  -- None-ls for additional linting and formatting
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = opts.sources or {}
      vim.list_extend(opts.sources, {
        -- JavaScript/TypeScript
        nls.builtins.diagnostics.eslint_d.with({
          condition = function(utils)
            return utils.root_has_file({ ".eslintrc.js", ".eslintrc.json", "eslint.config.js" })
          end,
        }),

        -- CSS/SCSS
        nls.builtins.diagnostics.stylelint.with({
          condition = function(utils)
            return utils.root_has_file({ ".stylelintrc", ".stylelintrc.json", "stylelint.config.js" })
          end,
        }),

        -- PHP
        nls.builtins.diagnostics.phpcs.with({
          args = { "--standard=PSR12", "--report=json", "-s", "$FILENAME" },
        }),
        nls.builtins.diagnostics.phpstan,
      })
    end,
  },
}