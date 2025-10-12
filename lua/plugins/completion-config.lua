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
          scss = { "lsp", "snippets", "buffer", "path" },
          css = { "lsp", "snippets", "buffer", "path" },
        },
        providers = {
          snippets = {
            score_offset = -3, -- Стандартный приоритет
            enabled = function()
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local after_cursor = line:sub(col + 1)

              -- Отключаем сниппеты внутри любых скобок если ничего не напечатано
              if (before_cursor:match("{%s*$") and after_cursor:match("^%s*}")) or
                 (before_cursor:match("%(%s*$") and after_cursor:match("^%s*%)")) or
                 (before_cursor:match("%[%s*$") and after_cursor:match("^%s*%]")) then
                return false
              end

              return true
            end,
          },
          lsp = {
            score_offset = 0, -- Стандартный LSP приоритет
            enabled = function()
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local after_cursor = line:sub(col + 1)

              -- Отключаем LSP внутри любых скобок если ничего не напечатано
              if (before_cursor:match("{%s*$") and after_cursor:match("^%s*}")) or
                 (before_cursor:match("%(%s*$") and after_cursor:match("^%s*%)")) or
                 (before_cursor:match("%[%s*$") and after_cursor:match("^%s*%]")) then
                return false
              end

              return true
            end,
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
                else
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
          show_on_x_blocked_trigger_characters = { '{', '}', '(', ')', '[', ']', '.', ':', ';' },
        },
        menu = {
          auto_show = function(ctx)
            if ctx.mode == 'cmdline' then
              return false
            end

            -- Для PHP файлов проверяем контекст
            if vim.bo.filetype == 'php' then
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local after_cursor = line:sub(col + 1)

              -- Отключаем автодополнение между открывающим и закрывающим HTML тегом
              -- Например: <div>|</div>
              if before_cursor:match(">%s*$") and after_cursor:match("^%s*</%w+>") then
                return false
              end
            end

            return true
          end,
        },
      },

      -- Fuzzy сортировка для приоритизации твоих снипетов
      fuzzy = {
        sorts = {
          function(a, b)
            -- Твои приоритетные снипеты
            local my_snippets = {'dv', 'pv', 'mcus', 'mc', 'mc5', 'mc7', 'mc9', 'mc12'}

            -- Vue директивы должны быть в приоритете
            local vue_directives = {'v-if', 'v-else', 'v-else-if', 'v-for', 'v-show', 'v-model', 'v-bind', 'v-on'}

            local a_is_my_snippet = a.source_name == "snippets" and vim.tbl_contains(my_snippets, a.label or "")
            local b_is_my_snippet = b.source_name == "snippets" and vim.tbl_contains(my_snippets, b.label or "")

            local a_is_vue_directive = vim.tbl_contains(vue_directives, a.label or "")
            local b_is_vue_directive = vim.tbl_contains(vue_directives, b.label or "")

            -- LSP (CSS свойства) должны быть выше твоих сниппетов в CSS контексте
            local filetype = vim.bo.filetype
            if filetype == "css" or filetype == "scss" then
              if a.source_name == "lsp" and b_is_my_snippet then
                return true
              end
              if b.source_name == "lsp" and a_is_my_snippet then
                return false
              end
            end

            -- Vue директивы всегда в приоритете над HTML тегами
            if a_is_vue_directive and not b_is_vue_directive then
              return true
            end
            if b_is_vue_directive and not a_is_vue_directive then
              return false
            end

            -- Если один твой снипет, а другой нет - твой выше (но НЕ в CSS)
            if not (filetype == "css" or filetype == "scss") then
              if a_is_my_snippet and not b_is_my_snippet then
                return true
              end
              if b_is_my_snippet and not a_is_my_snippet then
                return false
              end
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
        ["<CR>"] = {
          function(cmp)
            -- Если completion menu видимо - принимаем выбор
            if cmp.is_visible() then
              return cmp.accept()
            end

            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local before = line:sub(1, col)
            local after = line:sub(col + 1)

            -- Для PHP файлов
            if vim.bo.filetype == "php" then
              -- Если между HTML тегами: <div>|</div>
              if before:match(">%s*$") and after:match("^%s*</") then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR><Esc>O", true, false, true), "n", false)
                return
              end

              -- Если между PHP тегами: <?php | ?>
              if before:match("%<%?php%s*$") and after:match("^%s*%?>") then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR><CR><Up><Tab>", true, false, true), "n", false)
                return
              end
            end

            -- Для Vue, HTML, SCSS, CSS и других файлов: между тегами создаем пустую строку
            if vim.tbl_contains({"vue", "html", "scss", "css", "javascript", "typescript"}, vim.bo.filetype) then
              -- Если между HTML тегами: <div>|</div> или template тегами
              if before:match(">%s*$") and after:match("^%s*</") then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR><Esc>O", true, false, true), "n", false)
                return
              end

              -- Если между скобками: {|} или (|) или [|]
              if (before:match("{%s*$") and after:match("^%s*}")) or
                 (before:match("%(%s*$") and after:match("^%s*%)")) or
                 (before:match("%[%s*$") and after:match("^%s*%]")) then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR><Esc>O", true, false, true), "n", false)
                return
              end
            end

            -- Обычный Enter
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
          end,
        },
      },
    },
  },
}

