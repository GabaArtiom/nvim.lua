return {
  -- LuaSnip для создания сниппетов
  -- ВНИМАНИЕ: это единственный спек LuaSnip. Не заводи второй с ключом `config`
  -- в другом файле — lazy.nvim оставит только последний по алфавиту, и всё,
  -- что здесь настроено (в т.ч. защита от битых extmark'ов), молча пропадёт.
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local ls = require("luasnip")
      local session = require("luasnip.session")

      -- Обе ошибки ниже имеют одну причину: LuaSnip держит активную сессию
      -- сниппета, extmark'и которой уже недействительны (буфер перезаписали
      -- форматтером/автосейвом, сделали undo, перечитали файл).
      --
      --   str.lua:176      attempt to index a nil value  (при TextChanged)
      --   mark.lua:82      attempt to index a nil value  (при раскрытии сниппета)
      --
      -- Дальше — три слоя защиты: сбросить мёртвую сессию до раскрытия,
      -- переживать сбой при восстановлении курсора, и штатный авто-выход
      -- из сниппета по событиям.

      -- Возвращает true, если текущая сессия непригодна и была сброшена.
      local function drop_broken_session()
        local buf = vim.api.nvim_get_current_buf()
        local node = session.current_nodes[buf]
        if not node then
          return false
        end

        local ok, valid = pcall(function()
          return node.parent.snippet:extmarks_valid()
        end)
        if ok and valid then
          return false
        end

        -- unlink_current сам ходит по тем же extmark'ам, поэтому под pcall;
        -- если и он падает — рвём связь грубо, лишь бы не тащить труп дальше.
        if not pcall(ls.unlink_current) then
          session.current_nodes[buf] = nil
        end
        return true
      end

      -- 1. mark.lua:82 — раскрытие сниппета пытается вложить его в мёртвую
      --    сессию. Чистим сессию до раскрытия. Оборачиваем каждую точку входа
      --    отдельно: ls.expand() внутри зовёт локальную _snip_expand в обход
      --    ls.snip_expand (init.lua:716), одной обёртки не хватит.
      --    blink ходит через snip_expand, твой <CR>-хендлер — через expand.
      for _, name in ipairs({ "snip_expand", "expand", "expand_auto", "lsp_expand" }) do
        local orig = ls[name]
        if type(orig) == "function" then
          ls[name] = function(...)
            drop_broken_session()
            return orig(...)
          end
        end
      end

      -- 2. str.lua:176 — node_update_dependents_preserve_position зовёт
      --    store_cursor_node_relative ВНЕ своего pcall (init.lua:205), поэтому
      --    ошибка убивает автокоманду и сессию целиком. Ловим сами: худшее, что
      --    случится — курсор восстановится не идеально точно.
      local node_util = require("luasnip.nodes.util")
      local orig_store = node_util.store_cursor_node_relative
      node_util.store_cursor_node_relative = function(node, opts)
        local ok, res = pcall(orig_store, node, opts)
        if ok then
          return res
        end
        return { store_ids = {} }
      end

      -- Загружаем friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Загрузка кастомных снипетов из конфига nvim
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

      -- Настройка LuaSnip
      ls.config.set_config({
        -- История сниппетов
        history = true,
        -- Обновление динамических сниппетов
        updateevents = "TextChanged,TextChangedI",
        -- 3. Штатный авто-выход: удаление текста сниппета закрывает сессию,
        --    уход курсора за его границы — тоже. Без этого мёртвая сессия
        --    живёт до следующего падения.
        delete_check_events = "TextChanged,InsertLeave",
        region_check_events = "CursorMoved,CursorMovedI,InsertEnter",
      })

      -- Клавиши для выбора вариантов в снипетах
      vim.keymap.set("i", "<Caps_Lock>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true, desc = "Select next choice in snippet" })
    end,
  },
}
