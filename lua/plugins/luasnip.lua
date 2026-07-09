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

      -- Guard against an upstream LuaSnip bug (str.lua multiline_substr: "attempt
      -- to index a nil value") that crashes on <Tab>/<S-Tab> jumps. On jump,
      -- node_update_dependents_preserve_position calls store_cursor_node_relative
      -- OUTSIDE the pcall that wraps the dependents-update, so when a node's
      -- extmark region goes stale (common on nvim 0.12), the error escapes and
      -- breaks the whole snippet session. Wrap the store call so a failure
      -- degrades to "cursor not perfectly restored" instead of a crash.
      local node_util = require("luasnip.nodes.util")
      local orig_store = node_util.store_cursor_node_relative
      node_util.store_cursor_node_relative = function(node, opts)
        local ok, res = pcall(orig_store, node, opts)
        if ok then
          return res
        end
        return { store_ids = {} }
      end

      -- Загружаем friendly-snippets полностью
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Также загружаем снипеты для конкретных языков
      require("luasnip.loaders.from_vscode").lazy_load({paths = {"~/.local/share/nvim/lazy/friendly-snippets"}})

      -- Загружаем кастомные снипеты из отдельных файлов
      vim.schedule(function()
        require("luasnip.loaders.from_lua").load({paths = "~/.config/nvim/lua/snippets"})
      end)


      -- Настройка LuaSnip
      ls.config.set_config({
        -- История сниппетов
        history = true,
        -- Обновление динамических сниппетов
        updateevents = "TextChanged,TextChangedI",
        -- Удаление текста при выходе из сниппета
        delete_check_events = "TextChanged",
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