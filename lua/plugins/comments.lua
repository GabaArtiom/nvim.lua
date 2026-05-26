return {
  {
    "folke/ts-comments.nvim",
    opts = {
      lang = {
        css = "/* %s */",
        -- First entry is used for commenting; all entries are recognised when
        -- uncommenting, so `gcc` also toggles off legacy `//` line comments.
        scss = { "/* %s */", "// %s" },
        sass = { "/* %s */", "// %s" },
        less = { "/* %s */", "// %s" },
      },
    },
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
}