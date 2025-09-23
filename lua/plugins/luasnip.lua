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