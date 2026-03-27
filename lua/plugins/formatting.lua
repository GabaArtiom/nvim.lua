return {
  -- Conform for formatting
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      log_level = vim.log.levels.DEBUG,
      formatters_by_ft = {
        ["javascript"] = { "prettierd", "prettier" },
        ["javascriptreact"] = { "prettierd", "prettier" },
        ["typescript"] = { "prettierd", "prettier" },
        ["typescriptreact"] = { "prettierd", "prettier" },
        ["vue"] = { "prettierd", "prettier" },
        ["css"] = { "oxfmt" },
        ["scss"] = { "oxfmt" },
        ["sass"] = { "prettier" },
        ["less"] = { "prettier" },
        ["html"] = { "prettierd", "prettier" },
        ["json"] = { "prettierd", "prettier" },
        ["jsonc"] = { "prettierd", "prettier" },
        ["yaml"] = { "prettierd", "prettier" },
        ["markdown"] = { "prettierd", "prettier" },
        ["markdown.mdx"] = { "prettierd", "prettier" },
        ["graphql"] = { "prettierd", "prettier" },
        ["handlebars"] = { "prettierd", "prettier" },
        ["php"] = { "prettierd-blade" },
        ["blade"] = { "prettierd-blade" },
      },
      formatters = {
        ["prettierd-blade"] = {
          command = vim.fn.expand("~/.local/share/nvim/mason/bin/prettierd"),
          args = function(_, ctx)
            local basename = vim.fn.fnamemodify(ctx.filename, ":t"):gsub("%.php$", ".blade.php")
            return { basename }
          end,
          stdin = true,
        },
        ["js-beautify-php"] = {
          command = vim.fn.expand("~/.config/nvm/versions/node/v20.19.1/bin/js-beautify"),
          args = { "--type=html", "--templating=php", "--indent-size=2", "-f", "-" },
          stdin = true,
        },
        ["blade-formatter"] = {
          command = "blade-formatter",
          args = {
            "--stdin",
            "--config",
            vim.fn.expand("~/.config/nvim/.bladeformatterrc.json"),
          },
          stdin = true,
        },
        ["php-cs-fixer"] = {
          command = vim.fn.expand("~/.local/bin/php-cs-fixer"),
          args = {
            "fix",
            "--config=" .. vim.fn.expand("~/.config/nvim/.php-cs-fixer.php"),
            "--using-cache=no",
            "$FILENAME",
          },
          stdin = false,
        },
        prettier = {
          command = vim.fn.expand("~/.local/share/nvim/mason/bin/prettier"),
          args = { "--stdin-filepath", "$FILENAME" },
          stdin = true,
        },
        ["prettier-php"] = {
          command = vim.fn.expand("~/.local/share/nvim/mason/bin/prettier"),
          args = {
            "--plugin="
              .. vim.fn.expand(
                "~/.local/share/nvim/mason/packages/prettier/node_modules/@prettier/plugin-php/src/index.mjs"
              ),
            "--stdin-filepath",
            "$FILENAME",
          },
          stdin = true,
        },
        stylelint = {
          command = vim.fn.expand("~/.local/share/nvim/mason/bin/stylelint"),
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
