return {
  -- blink.cmp для автодополнения
  {
    "saghen/blink.cmp",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    },
    version = "v0.*",
    opts = {
      -- Используем preset luasnip
      snippets = {
        preset = "luasnip",
      },

      -- Простая конфигурация источников
      sources = {
        default = { "lsp", "snippets", "buffer", "path" },
        per_filetype = {
          html = { "lsp", "snippets", "buffer", "path" },
          vue = { "lsp", "snippets", "buffer", "path" },
        },
        providers = {
          snippets = {
            score_offset = -3, -- Стандартный приоритет
            enabled = function()
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local after_cursor = line:sub(col + 1)

              -- Отключаем сниппеты между скобками
              if before_cursor:match("{%s*$") and after_cursor:match("^%s*}") then
                return false
              end

              return true
            end,
          },
          lsp = {
            score_offset = 0, -- Стандартный LSP приоритет
            transform_items = function(ctx, items)
              local blacklist = require('config.snippet-blacklist')
              local filtered_items = {}

              for _, item in ipairs(items) do
                -- Проверяем blacklist для снипетов из LSP
                local is_blacklisted = false
                if item.kind == vim.lsp.protocol.CompletionItemKind.Snippet then
                  for _, blocked in ipairs(blacklist) do
                    if item.label == blocked then
                      is_blacklisted = true
                      break
                    end
                  end
                end

                -- Добавляем только если не в blacklist
                if not is_blacklisted then
                  table.insert(filtered_items, item)
                end
              end
              return filtered_items
            end,
          },
          buffer = {
            score_offset = -100, -- Понижаем buffer до минимума
            transform_items = function(ctx, items)
              local filtered = {}
              for _, item in ipairs(items) do
                -- Блокируем всякие "div abc" и подобную хрень из buffer
                if not (item.label and item.label:match("div%s") or item.label:match("abc")) then
                  table.insert(filtered, item)
                end
              end
              return filtered
            end,
          },
          path = {
            score_offset = 30,
          },
        },
      },

      -- Настройки completion
      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = {
          enabled = false,
        },
        trigger = {
          -- Отключаем автоматический показ при вводе символов
          show_on_insert_on_trigger_character = false,
        },
      },

      -- Fuzzy сортировка для приоритизации твоих снипетов
      fuzzy = {
        sorts = {
          function(a, b)
            -- Твои приоритетные снипеты
            local my_snippets = {'dv', 'pv', 'mcus', 'mc', 'mc5', 'mc7', 'mc9', 'mc12'}

            local a_is_my_snippet = a.source_name == "snippets" and vim.tbl_contains(my_snippets, a.label or "")
            local b_is_my_snippet = b.source_name == "snippets" and vim.tbl_contains(my_snippets, b.label or "")

            -- Если один твой снипет, а другой нет - твой выше
            if a_is_my_snippet and not b_is_my_snippet then
              return true
            end
            if b_is_my_snippet and not a_is_my_snippet then
              return false
            end

            return nil -- Стандартная сортировка
          end,
          'score',
          'sort_text',
        }
      },

      -- Настраиваем клавиши
      keymap = {
        preset = "default",
        ["<Tab>"] = { "snippet_forward", "accept", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
      },
    },
  },
}

