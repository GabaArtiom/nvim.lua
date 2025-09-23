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