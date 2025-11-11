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
          lsp = {},
          snippets = {
            transform_items = function(ctx, items)
              -- Получаем что пользователь напечатал
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local before_cursor = line:sub(1, col)
              local query = before_cursor:match("[%w_%-]+$") or ""

              -- Список твоих кастомных сниппетов
              local my_snippets = {
                "mc5", "mc7", "mc9", "mc12", "mcus", "mc",
                "mbl", "min", "pbl", "pin",
                "pa", "dfb", "dfc", "vr", "bf", "af",
                "dv", "pv", "cl", "dqs", "fun"
              }

              -- Для каждого сниппета проверяем точное совпадение
              for _, item in ipairs(items) do
                local is_my_snippet = vim.tbl_contains(my_snippets, item.label or "")
                local exact_match = (item.label == query)

                -- Если МОЙ snippet И точное совпадение - огромный boost!
                if is_my_snippet and exact_match then
                  item.score_offset = (item.score_offset or 0) + 1000
                end
              end

              return items
            end,
          },
          buffer = {
            min_keyword_length = 4,
          },
          path = {},
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
          show_on_x_blocked_trigger_characters = { "{", "}", "(", ")", "[", "]", ".", ":", ";" },
        },
        menu = {
          auto_show = function(ctx)
            if ctx.mode == "cmdline" then
              return false
            end

            -- Для PHP файлов проверяем контекст
            if vim.bo.filetype == "php" then
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

      -- Исправляем cmdline keymap из LazyVim (false -> пустые таблицы)
      cmdline = {
        keymap = {
          ["<Right>"] = {},
          ["<Left>"] = {},
        },
      },


      -- Настраиваем клавиши
      keymap = {
        preset = "default",
        -- Tab используется для tabout.nvim (выход из скобок)
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
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
                vim.api.nvim_feedkeys(
                  vim.api.nvim_replace_termcodes("<CR><CR><Up><Tab>", true, false, true),
                  "n",
                  false
                )
                return
              end
            end

            -- Для Vue, HTML, SCSS, CSS и других файлов: между тегами создаем пустую строку
            if vim.tbl_contains({ "vue", "html", "scss", "css", "javascript", "typescript" }, vim.bo.filetype) then
              -- Если между HTML тегами: <div>|</div> или template тегами
              if before:match(">%s*$") and after:match("^%s*</") then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR><Esc>O", true, false, true), "n", false)
                return
              end

              -- Если между скобками: {|} или (|) или [|]
              if
                (before:match("{%s*$") and after:match("^%s*}"))
                or (before:match("%(%s*$") and after:match("^%s*%)"))
                or (before:match("%[%s*$") and after:match("^%s*%]"))
              then
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
