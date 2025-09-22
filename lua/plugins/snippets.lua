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

      -- Загружаем friendly-snippets (все кроме исключенных)
      require("luasnip.loaders.from_vscode").lazy_load({
        exclude = { "php", "html" }  -- исключаем PHP и HTML снипеты из friendly-snippets
      })

      -- Загрузка кастомных снипетов из конфига nvim (абсолютный путь)
      local function load_custom_snippets()
        local config_path = vim.fn.stdpath("config")
        local snippets_path = config_path .. "/lua/snippets"

        -- Проверяем что папка существует
        if vim.fn.isdirectory(snippets_path) == 0 then
          return
        end

        local snippet_files = { "html", "scss", "js" }

        for _, file in ipairs(snippet_files) do
          local file_path = snippets_path .. "/" .. file .. ".lua"
          if vim.fn.filereadable(file_path) == 1 then
            -- Загружаем файл напрямую
            local ok, lang_table = pcall(dofile, file_path)
            if ok and lang_table then
              for lang, snippets in pairs(lang_table) do
                ls.add_snippets(lang, snippets)
              end
            end
          end
        end
      end

      load_custom_snippets()

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
        default = { "snippets", "lsp", "path", "buffer" },

        providers = {
          -- Поднимаем приоритет снипетов
          snippets = {
            score_offset = 200, -- Highest priority for snippets
          },
          -- Применяем блэклист ко всем LSP элементам
          lsp = {
            score_offset = 100, -- Boost LSP completions (imports, functions)
            transform_items = function(ctx, items)
              return vim.tbl_filter(function(item)
                local label = item.label or ""

                -- Проверяем блэклист для всех LSP элементов
                for _, blocked in ipairs(blacklist) do
                  if label == blocked then
                    return false -- блокируем элемент из блэклиста
                  end
                end

                return true
              end, items)
            end,
          },


          -- Применяем блэклист к buffer провайдеру
          buffer = {
            transform_items = function(ctx, items)
              return vim.tbl_filter(function(item)
                local label = item.label or ""

                -- Проверяем блэклист для buffer элементов
                for _, blocked in ipairs(blacklist) do
                  if label == blocked then
                    return false -- блокируем элемент из блэклиста
                  end
                end

                return true
              end, items)
            end,
          },

          -- Применяем блэклист к path провайдеру
          path = {
            transform_items = function(ctx, items)
              return vim.tbl_filter(function(item)
                local label = item.label or ""

                -- Проверяем блэклист для path элементов
                for _, blocked in ipairs(blacklist) do
                  if label == blocked then
                    return false -- блокируем элемент из блэклиста
                  end
                end

                return true
              end, items)
            end,
          },
        },

        transform_items = function(ctx, items)
          -- Deduplicate items first
          local seen = {}
          local deduplicated = {}

          for _, item in ipairs(items) do
            local label = item.label or ""
            if not seen[label] then
              seen[label] = true
              table.insert(deduplicated, item)
            end
          end

          -- Filter in Vue files
          if vim.bo.filetype == 'vue' then
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local before_cursor = line:sub(1, col)
            local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

            -- Check current context
            local in_template = false
            local in_script = false
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

            -- Find which section we're in
            for i = 1, cursor_line do
              local current_line = lines[i]
              if current_line and current_line:match("^%s*<template") then
                in_template = true
                in_script = false
              elseif current_line and current_line:match("^%s*<script") then
                in_script = true
                in_template = false
              elseif current_line and current_line:match("^%s*</template>") then
                in_template = false
              elseif current_line and current_line:match("^%s*</script>") then
                in_script = false
              end
            end

            -- Filter HTML completions in script sections or when inside template tags
            local should_filter = (in_script) or (in_template and before_cursor:match("<%w+[^>]*$"))

            if should_filter then
              return vim.tbl_filter(function(item)
                local label = item.label or ""
                local kind = item.kind

                -- In script sections, block all HTML-related completions
                if in_script then
                  -- Block HTML tags and Vue directives
                  if (kind == vim.lsp.protocol.CompletionItemKind.Snippet or
                      kind == vim.lsp.protocol.CompletionItemKind.Text) and
                     (label:match("^[a-z]+$") or label:match("^v[A-Z]") or
                      label:match("^#") or label:match("@") or
                      label == "useRouter" or label == "useRoute" or
                      label:match("Component") or label:match("Layout") or
                      label:match("Error") or label:match("region")) then
                    return false
                  end
                else
                  -- In template sections, only block simple HTML tags when inside tags
                  if (kind == vim.lsp.protocol.CompletionItemKind.Snippet or
                      kind == vim.lsp.protocol.CompletionItemKind.Text) and
                     label:match("^[a-z]+$") and not (
                     label == 'class' or label == 'id' or label == 'style' or
                     label == 'ref' or label == 'key' or label == 'slot' or label == 'is') then
                    return false
                  end
                end

                return true
              end, deduplicated)
            end
          end

          return deduplicated
        end,
      }

      -- Настройки completion для правильной работы с фигурными скобками
      opts.completion = {
        list = {
          selection = { preselect = true, auto_insert = false },
        },
        accept = {
          auto_brackets = {
            enabled = true,
          }
        },
        ghost_text = {
          enabled = false
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        trigger = {
          show_on_blocked_trigger_characters = { '{', '}' },
          context = function()
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local before_cursor = line:sub(1, col)
            local after_cursor = line:sub(col + 1)

            -- Не показывать автодополнение если курсор между пустыми фигурными скобками
            if before_cursor:match("%{%s*$") and after_cursor:match("^%s*%}") then
              return false
            end

            return true
          end,
        },
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

