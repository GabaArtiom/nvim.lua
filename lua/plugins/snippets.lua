return {
  -- LuaSnip для создания сниппетов
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node
      local f = ls.function_node

      -- Загружаем friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Загрузка из отдельных файлов
      local function load_all_snippets()
        local loaded = {
          require("snippets.html"),
          require("snippets.scss"),
          require("snippets.js"),
        }

        for _, lang_table in ipairs(loaded) do
          for lang, snippets in pairs(lang_table) do
            ls.add_snippets(lang, snippets)
          end
        end
      end

      load_all_snippets()

      -- Добавляем простой тестовый снипет для проверки
      ls.add_snippets("all", {
        s("test", {
          t("This is a test snippet: "),
          i(1, "placeholder"),
        })
      })

      -- Настройка LuaSnip
      ls.config.set_config({
        -- История сниппетов
        history = true,
        -- Обновление динамических сниппетов
        updateevents = "TextChanged,TextChangedI",
        -- Удаление текста при выходе из сниппета
        delete_check_events = "TextChanged",
      })

      -- Оставляем только Caps Lock для выбора вариантов в снипетах
      -- Tab и Shift+Tab теперь управляются через blink.cmp
      vim.keymap.set("i", "<Caps_Lock>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true, desc = "Select next choice in snippet" })
    end,
  },

  -- Настраиваем blink.cmp для работы с LuaSnip
  {
    "saghen/blink.cmp",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    },
    version = "v0.*",
    opts = function(_, opts)
      -- КЛЮЧЕВОЕ: используем preset luasnip
      opts.snippets = {
        preset = "luasnip"
      }

      -- Настраиваем источники с блэклистом
      local blacklist = require("config.snippet-blacklist")

      opts.sources = {
        default = { "lsp", "path", "snippets", "buffer" },

        providers = {
          -- Применяем блэклист только к LSP снипетам
          lsp = {
            transform_items = function(ctx, items)
              return vim.tbl_filter(function(item)
                local label = item.label or ""
                local kind = item.kind

                -- Если это снипет от LSP, проверяем блэклист
                if kind == require('blink.cmp.types').CompletionItemKind.Snippet then
                  for _, blocked in ipairs(blacklist) do
                    if label == blocked then
                      return false -- блокируем LSP снипет из блэклиста
                    end
                  end
                end

                return true
              end, items)
            end,
          }
        }
      }

      -- Настраиваем клавиши
      opts.keymap = {
        preset = "default",

        -- Tab для принятия и расширения снипетов
        ["<Tab>"] = { "snippet_forward", "select_and_accept", "fallback" },

        -- Shift+Tab для обратного движения по снипетам
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },

        -- Enter для подтверждения выбора
        ["<CR>"] = { "accept", "fallback" },

        -- Caps Lock для навигации вниз
        ["<Caps_Lock>"] = { "select_next", "fallback" },

        -- Shift+Caps Lock для навигации вверх
        ["<S-Caps_Lock>"] = { "select_prev", "fallback" },

        -- Ctrl+j/k для навигации
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
      }

      return opts
    end,
  },
}

