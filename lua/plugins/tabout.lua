return {
  {
    "abecodes/tabout.nvim",
    lazy = false,
    event = "InsertCharPre",
    priority = 1000,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      require("tabout").setup({
        tabkey = "<Tab>",
        backwards_tabkey = "<S-Tab>",
        act_as_tab = true, -- Tab ведет себя как обычный Tab если не внутри пары
        act_as_shift_tab = false,
        default_tab = "<C-t>", -- Fallback для обычного Tab
        default_shift_tab = "<C-d>", -- Fallback для Shift+Tab
        enable_backwards = true,
        completion = false, -- Отключаем интеграцию с nvim-cmp (используем blink.cmp)
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
        },
        ignore_beginning = true, -- Игнорировать в начале строки
        exclude = {}, -- Файлы где не работает
      })
    end,
  },
}
