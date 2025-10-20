return {
  -- HTML/CSS support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable duplicate Vue servers, use only volar
        vue_ls = false,
        vuels = {
          enabled = false,
        },

        -- Enable volar in TAKEOVER MODE (handles everything including TS/JS)
        volar = {
          filetypes = { "vue", "typescript", "javascript", "javascriptreact", "typescriptreact" },
          init_options = {
            vue = {
              hybridMode = false,
            },
            typescript = {
              tsdk = vim.fn.getcwd() .. "/node_modules/typescript/lib",
            },
          },
          settings = {
            vue = {
              server = {
                vitePress = {
                  supportMdFile = true,
                },
              },
            },
            typescript = {
              preferences = {
                importModuleSpecifier = "relative",
              },
              suggest = {
                autoImports = true,
              },
            },
            javascript = {
              preferences = {
                importModuleSpecifier = "relative",
              },
              suggest = {
                autoImports = true,
              },
            },
          },
        },

        -- Keep emmet for Vue + HTML/CSS
        emmet_ls = {
          filetypes = { "html", "css", "scss", "sass", "less", "vue", "php" },
        },

        html = {
          filetypes = { "html", "templ", "php" },
        },
        cssls = {
          filetypes = { "css", "scss", "sass", "less" },
          settings = {
            css = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
            scss = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
            less = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
          },
        },
        -- PHP Language Server (Intelephense)
        intelephense = {
          settings = {
            intelephense = {
              stubs = {
                "bcmath",
                "bz2",
                "calendar",
                "Core",
                "curl",
                "date",
                "dba",
                "dom",
                "enchant",
                "fileinfo",
                "filter",
                "ftp",
                "gd",
                "gettext",
                "hash",
                "iconv",
                "imap",
                "intl",
                "json",
                "ldap",
                "libxml",
                "mbstring",
                "mcrypt",
                "mysql",
                "mysqli",
                "password",
                "pcntl",
                "pcre",
                "PDO",
                "pdo_mysql",
                "Phar",
                "readline",
                "recode",
                "Reflection",
                "regex",
                "session",
                "SimpleXML",
                "soap",
                "sockets",
                "sodium",
                "SPL",
                "standard",
                "superglobals",
                "sysvsem",
                "sysvshm",
                "tokenizer",
                "xml",
                "xdebug",
                "xmlreader",
                "xmlwriter",
                "yaml",
                "zip",
                "zlib",
                "wordpress",
                "woocommerce",
                "/home/gaba/.config/nvim/stubs/acf-pro-stubs.php",
              },
              -- Пути к дополнительным файлам
              includePaths = {
                "/home/gaba/.config/nvim/stubs",
              },
              diagnostics = {
                enable = true,
              },
              completion = {
                insertUseDeclaration = true,
                fullyQualifyGlobalConstantsAndFunctions = false,
                suggestObjectOperatorStaticMethods = true,
                maxItems = 100,
              },
              -- Дополнительные настройки для лучшей работы
              environment = {
                phpVersion = "8.0.0",
                includePaths = {
                  "/home/gaba/.config/nvim/stubs",
                }
              },
            },
          },
        },
      },
      setup = {
        -- Prevent vue_ls from loading
        vue_ls = function()
          return true
        end,
      },
    },
  },

  -- Enhanced treesitter for web development
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "html",
        "css",
        "scss",
        "sass",
        "javascript",
        "typescript",
        "tsx",
        "vue",
        "php",
        "phpdoc",
        "json",
        "json5",
        "yaml",
        "markdown",
        "markdown_inline",
      })

      -- Включаем фолдинг через treesitter для PHP и HTML
      opts.fold = true
      opts.highlight = opts.highlight or {}
      opts.highlight.enable = true
      opts.highlight.additional_vim_regex_highlighting = false

      -- Настройки для PHP с HTML
      opts.php = {
        enable = true,
      }
    end,
  },

  -- Mason tool installer
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Language servers
        "html-lsp",
        "css-lsp",
        "typescript-language-server",
        "vue-language-server",
        "intelephense",

        -- Formatters
        "prettier",
        "stylua",
        "php-cs-fixer",
        "prettierd", -- Faster prettier daemon

        -- Linters
        "eslint_d",
        "stylelint",
        "phpcs",
        "phpstan",
      },
    },
  },

  -- Auto pairs for web development
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
    opts = {
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
        java = false,
      },
    },
  },

  -- vim-closetag для PHP файлов
  {
    "alvan/vim-closetag",
    ft = { "php" },
    config = function()
      vim.g.closetag_filenames = "*.php"
      vim.g.closetag_xhtml_filenames = "*.php"
      vim.g.closetag_filetypes = "php"
      vim.g.closetag_xhtml_filetypes = "php"
      vim.g.closetag_emptyTags_caseSensitive = 1
      vim.g.closetag_regions = {
        ["php.embedded.html"] = "htmlTag",
      }
      vim.g.closetag_shortcut = ">"
      vim.g.closetag_close_shortcut = ""
    end,
  },

  -- Emmet support for HTML/CSS
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "scss", "sass", "vue", "jsx", "tsx", "php" },
    config = function()
      vim.g.user_emmet_leader_key = "<C-z>"
      vim.g.user_emmet_install_global = 0
      vim.cmd([[
        autocmd FileType html,css,scss,sass,vue,jsx,tsx,php EmmetInstall
      ]])
    end,
  },

  -- Better indentation for web files
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      scope = {
        show_start = false,
        show_end = false,
      },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "lazy",
          "mason",
        },
      },
    },
  },
}
